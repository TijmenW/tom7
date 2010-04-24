class Airplane extends Positionable {
  
  var holdingUp = false;
  var holdingLeft = false;
  var holdingRight = false;
  var holdingDown = false;
  var holdingEsc = false;
  var holdingSpace = false;
  var blockEsc = false;
  var escKey = 'esc';

  // Objects that don't need anything done except
  // to be removed if we leave the scene.
  // (in root now) var deleteme = [];

  var gamemusic : Sound;
  var volume : Number = 0;

  // Clip region for plane itself (death)
  var clip : MovieClip;

  // var dr : Number = 15;
  var dtheta : Number = 0;
  var theta : Number = 0;  // Right
  var dx : Number = 0;
  var dy : Number = 0;

  var pi : Number = 3.141592653589;

  public function onLoad() {

    gamemusic = new Sound(this);
    gamemusic.attachSound('bouncymp3');
    gamemusic.setVolume(0);
    volume = 0;
    gamemusic.start(0, 99999);

    Key.addListener(this);
    this.setdepth(1000);

    gamex = 20;
    gamey = 30;
  }

  var crabs = 0;

  public function onKeyDown() {
    var k = Key.getCode();
    switch(k) {
    case 192: // ~
      escKey = '~';
      break;
    case 82: // r
      escKey = 'r';
      if (!blockEsc) holdingEsc = true;
      break;
    case 27: // esc
      escKey = 'esc';
      if (!blockEsc) holdingEsc = true;
      break;
    case 32: // space
      /*
      crabs++;
      var c = 
        _root.attachMovie("bouncecrab", "bouncecrab" + crabs, 
                          900 + crabs,
                          {_x : this._x, _y : this._y});
      c.gamex = this.gamex;
      c.gamey = this.gamey;
      c.dx = this.dx;
      c.dy = this.dy;
      */
      holdingSpace = true;

      break;
    case 38: // up
      holdingUp = true;
      break;
    case 37: // left
      holdingLeft = true;
      break;
    case 39: // right
      holdingRight = true;
      break;
    case 40: // down
      holdingDown = true;
      break;
    }
  }

  public function onKeyUp() {
    var k = Key.getCode();
    switch(k) {
    case 192: // ~
    case 82: // r
    case 27: // esc
      holdingEsc = false;
      blockEsc = false;
      break;

    case 32:
      holdingSpace = false;
      break;
    case 38:
      holdingUp = false;
      break;
    case 37:
      holdingLeft = false;
      break;
    case 39:
      holdingRight = false;
      break;
    case 40:
      holdingDown = false;
      break;
    }
  }

  // These are latched: They physics code sets them
  // and the client must clear them.
  var collision_right = false;
  var collision_left = false;
  var collision_up = false;
  var collision_down = false;

  /* Starting at the 1-dimensional position 'pos' (which may not be
     blocked), move with velocity dpos along it. If the member
     function f returns true, then we are blocked; move to
     (approximately) the closest position where we're not blocked.
     Returns the new position and velocity (set to zero if we hit
     something.) */
  public function move1DClip(pos, dpos, f) {
    var newpos = pos + dpos;

    // XXX probably should check invariant since it can probably 
    // be violated in rare cases (fp issues).
    if (f.apply(this, [newpos])) {

      // invariant: pos is good, newpos is bad
      // XXX EPSILON?
      while (Math.abs(newpos - pos) > .01) {
        var mid = (newpos + pos) / 2;
        if (f.apply(this, [mid])) {
          newpos = mid;
        } else {
          pos = mid;
        }
      }

      return { pos : pos, dpos : 0 };
    } else {
      return { pos : newpos, dpos : dpos };
    }
  }

  public function blockedx(newx) {
    return _root.background.hit(_root.viewport.placex(newx), this._y);
  }

  public function blockedy(newy) {
    return _root.background.hit(this._x, _root.viewport.placey(newy));
  }

  public function onEnterFrame() {

    if (volume < 100) {
      volume += 5;
      gamemusic.setVolume(volume);
    }

    // Only physical quantities affect physical position.
    
    var oy = move1DClip(gamey, dy, blockedy);
    gamey = oy.pos;
    dy = oy.dpos;

    _root.viewport.place(this);

    // Now x:
    var ox = move1DClip(gamex, dx, blockedx);
    gamex = ox.pos;
    dx = ox.dpos;

    /*
    this.gamex += dx;
    this.gamey += dy;
    */

    /*
    this._rotation += 0.3;
    if (dy > 18) dy = 18;
    */

    // You are affected by gravity.
    dy += .1;

    // XXX: implement lift.

    // Pitch (theta) is influenced by dtheta
    this.theta += dtheta + 360;
    this.theta %= 360;

    // Then, I impart lift and thrust based on
    // my angle, changing my real physical
    // quantities.
    var sint = Math.sin(theta * 0.0174532925);
    var cost = Math.cos(theta * 0.0174532925);
    if (holdingSpace) {
      dy += 1.3 * sint;
      dx += .9 * cost;
    }

    // trace(theta + ' : ' + cost + ' -> ' + dx);

    if (dx > 16) dx = 16;
    else if (dx < -16) dx = -16;

    if (dy > 16) dy = 16;
    else if (dy < -16) dy = -16;

    // Then, the user is able to adjust the
    // intended angle and thrust.
    if (holdingDown) {
      dtheta -= 1;
      if (dtheta < -10) dtheta = -10;
    } else if (holdingUp) {
      dtheta += 1;
      if (dtheta > 10) dtheta = 10;
    } else {
      dtheta *= .7;
    }

    // Point in the direction of theta.
    this._rotation = theta;

    // Put the maximum amount of screen in front of me.
    // Don't actually force this because it looks too Tempest.
    // Instead, slide towards the desired pos.
    
    _root.viewport.setForPlane(gamex, gamey, theta, cost, sint);

    _root.viewport.place(this);
    _root.viewport.place(_root.background);

    var altitude = 1500 - this.gamey;
    _root.altimeter.setAltitude(altitude);

    /* XXX all game worlds should be enclosed
    if (this.gamey < -3000 || altitude <= -1500 ||
        this.gamex < -3000 || this.gamex > 3660) {
      die();
    }
    */

    // trace(this.clip._x);

    // Did I crash into the floor?
    if (_root.background.hit(this._x, this._y)) {
      // trace('collide with floor');
      // trace(' ');
      die();
    }
  }

  public function die() {
    for (var o in _root.deleteme) {
      _root.deleteme[o].removeMovieClip();
    }

    gamemusic.stop();
    this.removeMovieClip();
    _root.background.removeMovieClip();
    _root.altimeter.removeMovieClip();
    _root.gotoAndStop('isntland');
  }

}
