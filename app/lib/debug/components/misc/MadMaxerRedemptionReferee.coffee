Component = require 'lib/world/component'

module.exports = class MadMaxerRedemptionReferee extends Component
  @className: 'MadMaxerRedemptionReferee'
  chooseAction: ->
    null

  setUpLevel: ->
    @hollaback = {}
    @pairs = [
      { "peasant":"Merek", "ogre":"Dosha" }
      { "peasant":"Bernadette", "ogre":"Leerer" }
      { "peasant":"Paps", "ogre":"Ursa" }
      { "peasant":"Ellyn", "ogre":"Yugark" }
    ]

    # Shuffle so that the player can't just hardcode the order
    for h in [0...10]
      for i in [@pairs.length-1..1]
        j = @world.rand.rand(i-1)
        t = @pairs[j]
        @pairs[j] = @pairs[i]
        @pairs[i] = t

    for i in [0...@pairs.length]
      pea = @world.getThangByID(@pairs[i].peasant)
      pea.maxHealth *= @minPeasantHealthFactor + @incrPeasantHealthFactor * i
      pea.health = pea.maxHealth
      pea.scaleFactor *= 0.7 + 0.3 * i
      pea.addTrackedProperties(['maxHealth', 'number'])
      pea.keepTrackedProperty 'maxHealth'
      pea.keepTrackedProperty 'scaleFactor'
      # Peasants get a reference to the hollaback struct so that they can flag themselves when hearing commands.
      pea.hollaback = @hollaback
      @hollaback[@pairs[i].peasant] = false

    for a in [ "Mirana", "Oliver" ]
      archer = @world.getThangByID(a)
      if archer
        archer.hidden = true

  controlHumans: (friends) ->
    for f in friends
      # If a human got called out by the player, they should go home.
      continue unless @hollaback[f.id]
      if not f.homePoint
        f.homePoint = @pickPointFromRegions([@rectangles.homeZone])
      else if f.distanceTo(f.homePoint) > 4
        f.move(f.homePoint)
      else
        f.homePoint = null

      if @rectangles.homeZone.containsPoint(f.pos) and not f.hidden
        # Once the peasant is in its home area *and* the ogre chasing it is dead, hide it so it no longer shows up in findFriends()
        hideme = false
        o = ""
        for pair in @pairs
          if pair.peasant == f.id
            o = pair.ogre
        if o isnt ""
          ogre = @world.getThangByID(o)
          if ogre and ogre.health <= 0
            hideme = true
        if hideme
          f.hidden = true

  controlOgres: (ogres) ->
    for o in ogres
      if o.pos.x < @points.homeThreshold.x
        # Chase the weakest peasant in the home area.
        minh = 9999
        weakest = null
        for p in @world.thangs when p.exists and p.team == 'humans' and p.health > 0
          if p.health < minh
            minh = p.health
            weakest = p
        if weakest and o.target isnt weakest
          o.attack(weakest.id)
      else
        # Chase my assigned partner.
        pname = ""
        for pair in @pairs
          if pair.ogre == o.id
            pname = pair.peasant
        if pname isnt ""
          p = @world.getThangByID(pname)
          if p.exists and p.health > 0 and o.target isnt p
            o.attack(pname)
