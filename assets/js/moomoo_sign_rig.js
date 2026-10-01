/**
 * Holistic landmarks → Mixamo bone retarget for <model-viewer>.
 * Discovers bones via scene graph + SkinnedMesh.skeleton, forces redraws.
 */
(function () {
  'use strict';

  var CROSSFADE_SEC = 0.28;
  var IDLE_BLEND_SEC = 0.35;
  var POSE = {
    NOSE: 0,
    L_SHOULDER: 11,
    R_SHOULDER: 12,
    L_ELBOW: 13,
    R_ELBOW: 14,
    L_WRIST: 15,
    R_WRIST: 16,
    L_PINKY: 17,
    R_PINKY: 18,
    L_INDEX: 19,
    R_INDEX: 20,
    L_HIP: 23,
    R_HIP: 24,
  };
  var HAND = {
    WRIST: 0,
    THUMB_CMC: 1,
    THUMB_MCP: 2,
    THUMB_IP: 3,
    THUMB_TIP: 4,
    INDEX_MCP: 5,
    INDEX_PIP: 6,
    INDEX_DIP: 7,
    INDEX_TIP: 8,
    MIDDLE_MCP: 9,
    MIDDLE_PIP: 10,
    MIDDLE_DIP: 11,
    MIDDLE_TIP: 12,
    RING_MCP: 13,
    RING_PIP: 14,
    RING_DIP: 15,
    RING_TIP: 16,
    PINKY_MCP: 17,
    PINKY_PIP: 18,
    PINKY_DIP: 19,
    PINKY_TIP: 20,
  };

  var state = {
    ready: false,
    mv: null,
    scene: null,
    bones: {},
    rest: {},
    prefix: '',
    Vec3: null,
    Quat: null,
    playing: false,
    frames: [],
    fps: 15,
    index: 0,
    accum: 0,
    crossfade: 0,
    blendDuration: CROSSFADE_SEC,
    crossfading: false,
    fromPose: null,
    toPose: null,
    pendingPayload: null,
    raf: 0,
    lastTs: 0,
    loadAttempts: 0,
  };

  function smoothstep(t) {
    t = Math.max(0, Math.min(1, t));
    return t * t * (3 - 2 * t);
  }

  function notify(msg) {
    try {
      if (window.MooMooRigChannel && window.MooMooRigChannel.postMessage) {
        window.MooMooRigChannel.postMessage(String(msg));
      }
    } catch (e) {}
    try {
      console.log('[MooMooSignRig]', msg);
    } catch (e2) {}
  }

  function findModelViewer() {
    return document.querySelector('model-viewer');
  }

  function findScene(mv) {
    if (!mv) return null;
    var best = null;
    var keys = Reflect.ownKeys(mv);
    for (var i = 0; i < keys.length; i++) {
      try {
        var v = mv[keys[i]];
        if (!v || typeof v !== 'object') continue;
        // Prefer model-viewer's ModelScene (has queueRender).
        if (typeof v.queueRender === 'function' && (v.isScene || v.isObject3D)) {
          return v;
        }
        if (v.isScene) best = best || v;
        if (v.model && v.model.isObject3D) best = best || v.model;
      } catch (e) {}
    }
    if (mv.model) {
      try {
        if (mv.model.isObject3D) best = best || mv.model;
        var mkeys = Reflect.ownKeys(mv.model);
        for (var j = 0; j < mkeys.length; j++) {
          try {
            var mv2 = mv.model[mkeys[j]];
            if (mv2 && mv2.isObject3D) best = best || mv2;
          } catch (e2) {}
        }
      } catch (e3) {}
    }
    return best;
  }

  function detectPrefix(names) {
    for (var i = 0; i < names.length; i++) {
      var n = names[i];
      var m = /^(mixamorig\d*:)/.exec(n);
      if (m) return m[1];
      if (n.indexOf('mixamorig:') === 0) return 'mixamorig:';
    }
    return '';
  }

  function collectBones(root) {
    var map = {};
    if (!root || typeof root.traverse !== 'function') return map;
    root.traverse(function (obj) {
      if (obj.isBone || obj.type === 'Bone') {
        if (obj.name) map[obj.name] = obj;
      }
      if (obj.isSkinnedMesh && obj.skeleton && obj.skeleton.bones) {
        var bones = obj.skeleton.bones;
        for (var i = 0; i < bones.length; i++) {
          var b = bones[i];
          if (b && b.name) map[b.name] = b;
        }
      }
    });
    return map;
  }

  function bone(name) {
    return state.bones[state.prefix + name] || state.bones[name] || null;
  }

  function bindMath(sample) {
    if (!sample) return;
    state.Vec3 = sample.position.constructor;
    state.Quat = sample.quaternion.constructor;
  }

  function qClone(q) {
    return q.clone();
  }

  function qSlerp(a, b, t) {
    return a.clone().slerp(b, t);
  }

  function v3(x, y, z) {
    return new state.Vec3(x, y, z);
  }

  function mpToWorld(p) {
    if (!p || p.length < 2) return null;
    var x = Number(p[0]);
    var y = Number(p[1]);
    var z = p.length > 2 ? Number(p[2]) : 0;
    if (!isFinite(x) || !isFinite(y)) return null;
    return v3(x - 0.5, -(y - 0.5), -z * 0.6);
  }

  function getLm(list, idx) {
    if (!list || idx >= list.length) return null;
    return mpToWorld(list[idx]);
  }

  function mid(a, b) {
    if (!a || !b) return a || b || null;
    return v3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, (a.z + b.z) * 0.5);
  }

  function setFromUnitVectors(from, to) {
    var q = new state.Quat();
    q.setFromUnitVectors(from.clone().normalize(), to.clone().normalize());
    return q;
  }

  function aimLocal(boneObj, fromW, toW) {
    if (!boneObj || !fromW || !toW || !boneObj.parent) return null;
    var dir = toW.clone().sub(fromW);
    if (dir.lengthSq() < 1e-8) {
      return qClone(state.rest[boneObj.name] || boneObj.quaternion);
    }
    boneObj.parent.updateWorldMatrix(true, false);
    var parentWQ = new state.Quat();
    boneObj.parent.getWorldQuaternion(parentWQ);
    var worldQ = setFromUnitVectors(v3(0, 1, 0), dir);
    return parentWQ.clone().invert().multiply(worldQ);
  }

  function capturePose() {
    var pose = {};
    Object.keys(state.bones).forEach(function (name) {
      pose[name] = qClone(state.bones[name].quaternion);
    });
    return pose;
  }

  function applyPoseDict(pose) {
    Object.keys(pose).forEach(function (name) {
      var b = state.bones[name];
      if (b) b.quaternion.copy(pose[name]);
    });
    // Keep skin matrices in sync after manual quaternion writes.
    Object.keys(state.bones).forEach(function (name) {
      var b = state.bones[name];
      if (b) b.updateMatrix();
    });
    if (state.scene && typeof state.scene.updateMatrixWorld === 'function') {
      state.scene.updateMatrixWorld(true);
    }
  }

  function blendPoses(a, b, t) {
    var out = {};
    var keys = Object.keys(b);
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i];
      if (a[k] && b[k]) out[k] = qSlerp(a[k], b[k], t);
      else if (b[k]) out[k] = qClone(b[k]);
    }
    return out;
  }

  function fingerChain(hand, mcp, pip, dip, tip, boneNames) {
    var out = {};
    var pts = [getLm(hand, mcp), getLm(hand, pip), getLm(hand, dip), getLm(hand, tip)];
    for (var i = 0; i < boneNames.length; i++) {
      var b = bone(boneNames[i]);
      if (!b || !pts[i] || !pts[i + 1]) continue;
      var q = aimLocal(b, pts[i], pts[i + 1]);
      if (q) out[b.name] = q;
    }
    return out;
  }

  function computePoseFromFrame(frame) {
    var pose = {};
    var restNames = Object.keys(state.rest);
    for (var i = 0; i < restNames.length; i++) {
      pose[restNames[i]] = qClone(state.rest[restNames[i]]);
    }

    var P = frame.pose || [];
    var LH = frame.leftHand || [];
    var RH = frame.rightHand || [];

    var lShoulder = getLm(P, POSE.L_SHOULDER);
    var rShoulder = getLm(P, POSE.R_SHOULDER);
    var lElbow = getLm(P, POSE.L_ELBOW);
    var rElbow = getLm(P, POSE.R_ELBOW);
    var lWrist = getLm(P, POSE.L_WRIST);
    var rWrist = getLm(P, POSE.R_WRIST);
    var lHip = getLm(P, POSE.L_HIP);
    var rHip = getLm(P, POSE.R_HIP);
    var nose = getLm(P, POSE.NOSE);
    var hips = mid(lHip, rHip);
    var neck = mid(lShoulder, rShoulder);

    function setAim(name, from, to) {
      var b = bone(name);
      if (!b || !from || !to) return;
      var q = aimLocal(b, from, to);
      if (q) pose[b.name] = q;
    }

    if (hips && neck) {
      setAim('Spine', hips, neck);
      var midSpine = mid(hips, neck);
      setAim('Spine1', hips, midSpine || neck);
      setAim('Spine2', midSpine || hips, neck);
    }
    if (neck && nose) {
      setAim('Neck', neck, nose);
      setAim('Head', neck, nose);
    }

    setAim('LeftShoulder', neck || rShoulder, lShoulder);
    setAim('RightShoulder', neck || lShoulder, rShoulder);
    setAim('LeftArm', lShoulder, lElbow);
    setAim('RightArm', rShoulder, rElbow);
    setAim('LeftForeArm', lElbow, lWrist);
    setAim('RightForeArm', rElbow, rWrist);

    var lHand = getLm(LH, HAND.WRIST) || lWrist;
    var rHand = getLm(RH, HAND.WRIST) || rWrist;
    var lIndex = getLm(LH, HAND.INDEX_MCP) || getLm(P, POSE.L_INDEX);
    var rIndex = getLm(RH, HAND.INDEX_MCP) || getLm(P, POSE.R_INDEX);
    if (lHand && lIndex) setAim('LeftHand', lHand, lIndex);
    if (rHand && rIndex) setAim('RightHand', rHand, rIndex);

    function merge(dict) {
      Object.keys(dict).forEach(function (k) {
        pose[k] = dict[k];
      });
    }
    if (LH && LH.length >= 21) {
      merge(fingerChain(LH, HAND.THUMB_CMC, HAND.THUMB_MCP, HAND.THUMB_IP, HAND.THUMB_TIP, ['LeftHandThumb1', 'LeftHandThumb2', 'LeftHandThumb3']));
      merge(fingerChain(LH, HAND.INDEX_MCP, HAND.INDEX_PIP, HAND.INDEX_DIP, HAND.INDEX_TIP, ['LeftHandIndex1', 'LeftHandIndex2', 'LeftHandIndex3']));
      merge(fingerChain(LH, HAND.MIDDLE_MCP, HAND.MIDDLE_PIP, HAND.MIDDLE_DIP, HAND.MIDDLE_TIP, ['LeftHandMiddle1', 'LeftHandMiddle2', 'LeftHandMiddle3']));
      merge(fingerChain(LH, HAND.RING_MCP, HAND.RING_PIP, HAND.RING_DIP, HAND.RING_TIP, ['LeftHandRing1', 'LeftHandRing2', 'LeftHandRing3']));
      merge(fingerChain(LH, HAND.PINKY_MCP, HAND.PINKY_PIP, HAND.PINKY_DIP, HAND.PINKY_TIP, ['LeftHandPinky1', 'LeftHandPinky2', 'LeftHandPinky3']));
    }
    if (RH && RH.length >= 21) {
      merge(fingerChain(RH, HAND.THUMB_CMC, HAND.THUMB_MCP, HAND.THUMB_IP, HAND.THUMB_TIP, ['RightHandThumb1', 'RightHandThumb2', 'RightHandThumb3']));
      merge(fingerChain(RH, HAND.INDEX_MCP, HAND.INDEX_PIP, HAND.INDEX_DIP, HAND.INDEX_TIP, ['RightHandIndex1', 'RightHandIndex2', 'RightHandIndex3']));
      merge(fingerChain(RH, HAND.MIDDLE_MCP, HAND.MIDDLE_PIP, HAND.MIDDLE_DIP, HAND.MIDDLE_TIP, ['RightHandMiddle1', 'RightHandMiddle2', 'RightHandMiddle3']));
      merge(fingerChain(RH, HAND.RING_MCP, HAND.RING_PIP, HAND.RING_DIP, HAND.RING_TIP, ['RightHandRing1', 'RightHandRing2', 'RightHandRing3']));
      merge(fingerChain(RH, HAND.PINKY_MCP, HAND.PINKY_PIP, HAND.PINKY_DIP, HAND.PINKY_TIP, ['RightHandPinky1', 'RightHandPinky2', 'RightHandPinky3']));
    }
    return pose;
  }

  function queueRender() {
    if (state.scene && typeof state.scene.queueRender === 'function') {
      state.scene.queueRender();
    }
    if (state.mv) {
      try {
        if (typeof state.mv.requestUpdate === 'function') state.mv.requestUpdate();
      } catch (e) {}
      try {
        // Re-assert orbit so model-viewer marks the frame dirty.
        var orbit = state.mv.getAttribute('camera-orbit');
        if (orbit) state.mv.setAttribute('camera-orbit', orbit);
      } catch (e2) {}
    }
  }

  function tick(ts) {
    state.raf = requestAnimationFrame(tick);
    if (!state.ready) return;
    var dt = state.lastTs ? Math.min(0.05, (ts - state.lastTs) / 1000) : 0.016;
    state.lastTs = ts;

    if (!state.playing && !state.crossfading) return;

    if (state.crossfading && state.fromPose && state.toPose) {
      state.crossfade += dt;
      var dur = state.blendDuration > 0 ? state.blendDuration : CROSSFADE_SEC;
      var u = smoothstep(state.crossfade / dur);
      applyPoseDict(blendPoses(state.fromPose, state.toPose, u));
      queueRender();
      if (u >= 1) {
        state.crossfading = false;
        state.fromPose = null;
        state.toPose = null;
      }
      return;
    }

    if (!state.playing || !state.frames.length) return;

    var frameDur = 1 / Math.max(1, state.fps);
    state.accum += dt;
    while (state.accum >= frameDur && state.index < state.frames.length - 1) {
      state.accum -= frameDur;
      state.index += 1;
    }

    var i0 = Math.min(state.index, state.frames.length - 1);
    var i1 = Math.min(i0 + 1, state.frames.length - 1);
    var a = computePoseFromFrame(state.frames[i0]);
    var b = computePoseFromFrame(state.frames[i1]);
    var t = smoothstep(state.accum / frameDur);
    applyPoseDict(blendPoses(a, b, t));
    queueRender();

    if (i0 >= state.frames.length - 1 && state.accum >= frameDur) {
      state.playing = false;
    }
  }

  function tryBind() {
    var mv = state.mv || findModelViewer();
    if (!mv) return false;
    state.mv = mv;
    var scene = findScene(mv);
    if (!scene) {
      notify('waiting:scene:' + state.loadAttempts);
      return false;
    }
    state.scene = scene;
    state.bones = collectBones(scene);
    var names = Object.keys(state.bones);
    if (!names.length) {
      notify('waiting:bones:' + state.loadAttempts);
      return false;
    }
    state.prefix = detectPrefix(names);
    bindMath(state.bones[names[0]]);
    state.rest = {};
    names.forEach(function (n) {
      state.rest[n] = qClone(state.bones[n].quaternion);
    });
    state.ready = true;
    notify('ready:' + names.length + ':' + state.prefix);
    if (!state.raf) {
      state.lastTs = 0;
      state.raf = requestAnimationFrame(tick);
    }
    if (state.pendingPayload) {
      var pending = state.pendingPayload;
      state.pendingPayload = null;
      play(pending);
    }
    return true;
  }

  function init() {
    var mv = findModelViewer();
    if (!mv) {
      setTimeout(init, 80);
      return;
    }
    state.mv = mv;

    function onLoaded() {
      state.loadAttempts += 1;
      if (tryBind()) return;
      if (state.loadAttempts < 80) setTimeout(onLoaded, 120);
      else notify('error:no-bones');
    }

    if (mv.loaded) onLoaded();
    else mv.addEventListener('load', onLoaded, { once: true });
    // Some WebView builds fire load before our listener attaches.
    setTimeout(onLoaded, 250);
  }

  function play(payload) {
    if (!payload || !payload.frames || !payload.frames.length) {
      notify('play:empty');
      return;
    }
    if (!state.ready) {
      state.pendingPayload = payload;
      notify('play:queued:' + payload.frames.length);
      tryBind();
      return;
    }
    var first = computePoseFromFrame(payload.frames[0]);
    state.fromPose = capturePose();
    state.toPose = first;
    state.blendDuration = CROSSFADE_SEC;
    state.crossfade = 0;
    state.crossfading = true;
    state.frames = payload.frames;
    state.fps = payload.fps > 0 ? Number(payload.fps) : 15;
    state.index = 0;
    state.accum = 0;
    state.playing = true;
    notify('play:' + state.frames.length + '@' + state.fps);
    if (!state.raf) {
      state.lastTs = 0;
      state.raf = requestAnimationFrame(tick);
    }
    queueRender();
  }

  function stop(reset) {
    state.playing = false;
    if (reset && state.rest) {
      state.fromPose = capturePose();
      state.toPose = {};
      Object.keys(state.rest).forEach(function (k) {
        state.toPose[k] = qClone(state.rest[k]);
      });
      state.blendDuration = IDLE_BLEND_SEC;
      state.crossfade = 0;
      state.crossfading = true;
    } else {
      state.crossfading = false;
    }
  }

  window.MooMooSignRig = {
    play: play,
    stop: stop,
    isReady: function () {
      return !!state.ready;
    },
    status: function () {
      return {
        ready: state.ready,
        bones: Object.keys(state.bones).length,
        prefix: state.prefix,
        playing: state.playing,
        frames: state.frames.length,
      };
    },
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
