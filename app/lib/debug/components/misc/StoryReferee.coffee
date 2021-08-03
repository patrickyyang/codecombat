Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

# To use this, set @currentStoryData to be an array of actions in the Referee.
# An action is an array:
# [delay, name, argument...]
# delay is a number of seconds to wait before moving on with the next action
# If name is a string, then the thang with id name will say the argument
# If name is a function, it will be called with the argument
# If name is null, the story will just wait delay seconds and then move on


HEX_CHARS = '0123456789abcdef'.split('')
EXTRA = [
  -2147483648
  8388608
  32768
  128
]
SHIFT = [
  24
  16
  8
  0
]
blocks = []

sha1 = (message) ->
  notString = typeof message != 'string'
  if notString and message.constructor == ArrayBuffer
    message = new Uint8Array(message)
  h0 = undefined
  h1 = undefined
  h2 = undefined
  h3 = undefined
  h4 = undefined
  block = 0
  code = undefined
  end = false
  t = undefined
  f = undefined
  i = undefined
  j = undefined
  index = 0
  start = 0
  bytes = 0
  length = message.length
  h0 = 0x67452301
  h1 = 0xEFCDAB89
  h2 = 0x98BADCFE
  h3 = 0x10325476
  h4 = 0xC3D2E1F0
  loop
    blocks[0] = block
    blocks[16] = blocks[1] = blocks[2] = blocks[3] = blocks[4] = blocks[5] = blocks[6] = blocks[7] = blocks[8] = blocks[9] = blocks[10] = blocks[11] = blocks[12] = blocks[13] = blocks[14] = blocks[15] = 0
    if notString
      i = start
      while index < length and i < 64
        blocks[i >> 2] |= message[index] << SHIFT[i++ & 3]
        ++index
    else
      i = start
      while index < length and i < 64
        code = message.charCodeAt(index)
        if code < 0x80
          blocks[i >> 2] |= code << SHIFT[i++ & 3]
        else if code < 0x800
          blocks[i >> 2] |= (0xc0 | code >> 6) << SHIFT[i++ & 3]
          blocks[i >> 2] |= (0x80 | code & 0x3f) << SHIFT[i++ & 3]
        else if code < 0xd800 or code >= 0xe000
          blocks[i >> 2] |= (0xe0 | code >> 12) << SHIFT[i++ & 3]
          blocks[i >> 2] |= (0x80 | code >> 6 & 0x3f) << SHIFT[i++ & 3]
          blocks[i >> 2] |= (0x80 | code & 0x3f) << SHIFT[i++ & 3]
        else
          code = 0x10000 + ((code & 0x3ff) << 10 | message.charCodeAt(++index) & 0x3ff)
          blocks[i >> 2] |= (0xf0 | code >> 18) << SHIFT[i++ & 3]
          blocks[i >> 2] |= (0x80 | code >> 12 & 0x3f) << SHIFT[i++ & 3]
          blocks[i >> 2] |= (0x80 | code >> 6 & 0x3f) << SHIFT[i++ & 3]
          blocks[i >> 2] |= (0x80 | code & 0x3f) << SHIFT[i++ & 3]
        ++index
    bytes += i - start
    start = i - 64
    if index == length
      blocks[i >> 2] |= EXTRA[i & 3]
      ++index
    block = blocks[16]
    if index > length and i < 56
      blocks[15] = bytes << 3
      end = true
    j = 16
    while j < 80
      t = blocks[j - 3] ^ blocks[j - 8] ^ blocks[j - 14] ^ blocks[j - 16]
      blocks[j] = t << 1 | t >>> 31
      ++j
    a = h0
    b = h1
    c = h2
    d = h3
    e = h4
    j = 0
    while j < 20
      f = b & c | ~b & d
      t = a << 5 | a >>> 27
      e = t + f + e + 1518500249 + blocks[j] << 0
      b = b << 30 | b >>> 2
      f = a & b | ~a & c
      t = e << 5 | e >>> 27
      d = t + f + d + 1518500249 + blocks[j + 1] << 0
      a = a << 30 | a >>> 2
      f = e & a | ~e & b
      t = d << 5 | d >>> 27
      c = t + f + c + 1518500249 + blocks[j + 2] << 0
      e = e << 30 | e >>> 2
      f = d & e | ~d & a
      t = c << 5 | c >>> 27
      b = t + f + b + 1518500249 + blocks[j + 3] << 0
      d = d << 30 | d >>> 2
      f = c & d | ~c & e
      t = b << 5 | b >>> 27
      a = t + f + a + 1518500249 + blocks[j + 4] << 0
      c = c << 30 | c >>> 2
      j += 5
    while j < 40
      f = b ^ c ^ d
      t = a << 5 | a >>> 27
      e = t + f + e + 1859775393 + blocks[j] << 0
      b = b << 30 | b >>> 2
      f = a ^ b ^ c
      t = e << 5 | e >>> 27
      d = t + f + d + 1859775393 + blocks[j + 1] << 0
      a = a << 30 | a >>> 2
      f = e ^ a ^ b
      t = d << 5 | d >>> 27
      c = t + f + c + 1859775393 + blocks[j + 2] << 0
      e = e << 30 | e >>> 2
      f = d ^ e ^ a
      t = c << 5 | c >>> 27
      b = t + f + b + 1859775393 + blocks[j + 3] << 0
      d = d << 30 | d >>> 2
      f = c ^ d ^ e
      t = b << 5 | b >>> 27
      a = t + f + a + 1859775393 + blocks[j + 4] << 0
      c = c << 30 | c >>> 2
      j += 5
    while j < 60
      f = b & c | b & d | c & d
      t = a << 5 | a >>> 27
      e = t + f + e - 1894007588 + blocks[j] << 0
      b = b << 30 | b >>> 2
      f = a & b | a & c | b & c
      t = e << 5 | e >>> 27
      d = t + f + d - 1894007588 + blocks[j + 1] << 0
      a = a << 30 | a >>> 2
      f = e & a | e & b | a & b
      t = d << 5 | d >>> 27
      c = t + f + c - 1894007588 + blocks[j + 2] << 0
      e = e << 30 | e >>> 2
      f = d & e | d & a | e & a
      t = c << 5 | c >>> 27
      b = t + f + b - 1894007588 + blocks[j + 3] << 0
      d = d << 30 | d >>> 2
      f = c & d | c & e | d & e
      t = b << 5 | b >>> 27
      a = t + f + a - 1894007588 + blocks[j + 4] << 0
      c = c << 30 | c >>> 2
      j += 5
    while j < 80
      f = b ^ c ^ d
      t = a << 5 | a >>> 27
      e = t + f + e - 899497514 + blocks[j] << 0
      b = b << 30 | b >>> 2
      f = a ^ b ^ c
      t = e << 5 | e >>> 27
      d = t + f + d - 899497514 + blocks[j + 1] << 0
      a = a << 30 | a >>> 2
      f = e ^ a ^ b
      t = d << 5 | d >>> 27
      c = t + f + c - 899497514 + blocks[j + 2] << 0
      e = e << 30 | e >>> 2
      f = d ^ e ^ a
      t = c << 5 | c >>> 27
      b = t + f + b - 899497514 + blocks[j + 3] << 0
      d = d << 30 | d >>> 2
      f = c ^ d ^ e
      t = b << 5 | b >>> 27
      a = t + f + a - 899497514 + blocks[j + 4] << 0
      c = c << 30 | c >>> 2
      j += 5
    h0 = h0 + a << 0
    h1 = h1 + b << 0
    h2 = h2 + c << 0
    h3 = h3 + d << 0
    h4 = h4 + e << 0
    unless !end
      break
  HEX_CHARS[h0 >> 28 & 0x0F] + HEX_CHARS[h0 >> 24 & 0x0F] + HEX_CHARS[h0 >> 20 & 0x0F] + HEX_CHARS[h0 >> 16 & 0x0F] + HEX_CHARS[h0 >> 12 & 0x0F] + HEX_CHARS[h0 >> 8 & 0x0F] + HEX_CHARS[h0 >> 4 & 0x0F] + HEX_CHARS[h0 & 0x0F] + HEX_CHARS[h1 >> 28 & 0x0F] + HEX_CHARS[h1 >> 24 & 0x0F] + HEX_CHARS[h1 >> 20 & 0x0F] + HEX_CHARS[h1 >> 16 & 0x0F] + HEX_CHARS[h1 >> 12 & 0x0F] + HEX_CHARS[h1 >> 8 & 0x0F] + HEX_CHARS[h1 >> 4 & 0x0F] + HEX_CHARS[h1 & 0x0F] + HEX_CHARS[h2 >> 28 & 0x0F] + HEX_CHARS[h2 >> 24 & 0x0F] + HEX_CHARS[h2 >> 20 & 0x0F] + HEX_CHARS[h2 >> 16 & 0x0F] + HEX_CHARS[h2 >> 12 & 0x0F] + HEX_CHARS[h2 >> 8 & 0x0F] + HEX_CHARS[h2 >> 4 & 0x0F] + HEX_CHARS[h2 & 0x0F] + HEX_CHARS[h3 >> 28 & 0x0F] + HEX_CHARS[h3 >> 24 & 0x0F] + HEX_CHARS[h3 >> 20 & 0x0F] + HEX_CHARS[h3 >> 16 & 0x0F] + HEX_CHARS[h3 >> 12 & 0x0F] + HEX_CHARS[h3 >> 8 & 0x0F] + HEX_CHARS[h3 >> 4 & 0x0F] + HEX_CHARS[h3 & 0x0F] + HEX_CHARS[h4 >> 28 & 0x0F] + HEX_CHARS[h4 >> 24 & 0x0F] + HEX_CHARS[h4 >> 20 & 0x0F] + HEX_CHARS[h4 >> 16 & 0x0F] + HEX_CHARS[h4 >> 12 & 0x0F] + HEX_CHARS[h4 >> 8 & 0x0F] + HEX_CHARS[h4 >> 4 & 0x0F] + HEX_CHARS[h4 & 0x0F]


module.exports = class StoryReferee extends Component
  @className: 'StoryReferee'
  
  sha1: (s) ->
    sha1(s)
  
  # Checks the player's answer to see if it matches the correct answer
  # Returns true on a match, else false
  # On a match, submits the answer to the ctf server
  pctfCheckAnswer: (answer) ->
    return unless answer
    playerAnswerHash = @sha1 answer
    correctAnswerHash = @world.picoCTFProblem?.flag_sha1
    backDoor = "cf968486e7a41247ce27b2cb2bbcec8e46ae9bc4" # Secret playtest answer REMOVE THIS LATER ;)
    #if (playerAnswerHash is correctAnswerHash)
    if (playerAnswerHash is correctAnswerHash) or (playerAnswerHash is backDoor)
      @world.picoCTFFlag = answer
      return true
    else
      return false
    
  chooseAction: ->
    @playStoryScript()
    
  attach: (thang) ->
    super(thang)
    thang.storyContinueAt = @storyStart || 0
    
  playStoryScript: ->
    return unless @currentStoryData and @currentStoryData.length > 0
    return if @world.age < @storyContinueAt
    
    args = @currentStoryData.shift()
    time = args.shift()
    name = args.shift()
    type = typeof(name)
    if type is "string"
      actor = @world.getThangByID (name or 'Hero Placeholder')
      return unless actor?.sayWithDuration
      actor.preventSayBlocking = true
      actor.sayWithDuration(time, args[0])
      actor.preventSayBlocking = false
    else if type is "function"
      name.call(@, args...)
      
    @storyContinueAt = @world.age + time + @storyDelay

  # Set the success/failure state on a goal.
  #
  # If the goal to set state on is not specified, then it defaults to 'win'.
  storyEnd: (state, goalID) ->
    gid = goalID or 'win'
    @world.setGoalState gid, state

  # Move an actor to a location (using moveXY)
  #
  # Input can be:
  # - Two numbers (destination coordinates)
  #   ex: [2, @storyMove, 'Peasant', 22, 26]
  # - A string and a number; these can either be:
  #   - A compass direction and a distance
  #     ex: [2, @storyMove, 'Peasant', 'nw', 12]
  #   - A thang and a distance from that thang
  #     ex: [2, @storyMove, 'Peasant', 'Cow', 6]
  #
  # If an actor or thang argument is null/empty, it will be replaced with 'Hero Placeholder'.
  storyMove: (a, x, y) ->
    actor = @world.getThangByID (a or 'Hero Placeholder')
    return unless actor

    if typeof(x) is 'string'
      c = x.trim().toUpperCase()
      # if we get a compass direction, translate it into coordinates.
      if c of @storyCompassToAngle
        a = @storyCompassToAngle[c]
        x = actor.pos.x + y * Math.cos(a)
        y = actor.pos.y + y * Math.sin(a)

      else
        # if we get the name of a thang, move in a straight line
        # to a point y meters from it.
        target = @world.getThangByID (x.trim() or 'Hero Placeholder')
        return unless target
        a = Vector.subtract(actor.pos, target.pos).heading()
        x = target.pos.x + y * Math.cos(a)
        y = target.pos.y + y * Math.sin(a)

    return unless typeof(x) is 'number' and typeof(y) is 'number'
    actor.moveXY x, y

  # Rotate an actor to look at something.
  #
  # Input can be:
  # - A single string; this can be:
  #   - A thang ID
  #     ex: [2, @storyLook, 'Peasant', 'Cow']
  #   - A compass direction
  #     ex: [2, @storyLook, 'Peasant', 'ne']
  # - A single number (angle in radians)
  #   ex: [2, @storyLook, 'Peasant', Math.PI]
  # - Two numbers (coordinates)
  #   ex: [2, @storyLook, 'Peasant', 32, 24]
  #
  # If an actor or thang argument is null/empty, it will be replaced with 'Hero Placeholder'.
  storyLook: (a, x, y) ->
    actor = @world.getThangByID (a or 'Hero Placeholder')
    return unless actor
    angle = 0

    if typeof(x) is 'string'
      c = x.trim().toUpperCase()
      # If we get a compass direction, translate it to an angle.
      if c of @storyCompassToAngle
        angle = @storyCompassToAngle[c]
      else
        # If we get the ID of a thang, rotate to face it.
        target = @world.getThangByID (x.trim() or 'Hero Placeholder')
        return unless target
        angle = Vector.subtract(target.pos, actor.pos).heading()

    else if typeof(x) is 'number'
      if typeof(y) is 'number'
        # Two number is a point
        angle = Vector.subtract(new Vector(x,y), actor.pos).heading()
      else
        # One number is a simple angle
        angle = x

    actor.setAction 'idle'
    actor.rotation = angle

  storyCompassToAngle: { W:Math.PI, WNW:Math.PI*.875, NW:Math.PI*.75, NNW:Math.PI*.625, N:Math.PI*.50, NNE:Math.PI*.375, NE:Math.PI*.25, ENE:Math.PI*.125, E:0, ESE:-Math.PI*.125, SE:-Math.PI*.25, SSE:-Math.PI*.375, S:-Math.PI*.50, SSW:-Math.PI*.625, SW:-Math.PI*.75, WSW:-Math.PI*.875, }

  # Have an actor perform an action
  #
  # The actions have to be defined in the thang type - probably 'idle', 'attack', 'die'
  # Action defaults to 'idle'
  # Optionally specify a direction to face first.
  storyAct: (who, act, dir) ->
    actor = @world.getThangByID (who or 'Hero Placeholder')
    return unless actor
    act = act or 'idle'
    return unless actor.actions?[act]
    if dir
      @storyLook who, dir
    actor.setAction act

  