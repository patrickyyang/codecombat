Component = require 'lib/world/component'

module.exports = class KMeansReferee extends Component
  @className: "KMeansReferee"
  
  points: []
  
  getNearestCentroid: (centroids, point) ->
    nearest = centroids[0]
    nearestDistance = 90019001
    for centroid in centroids
      d2 = (centroid.x - point.x) * (centroid.x - point.x) + (centroid.y - point.y) * (centroid.y - point.y)
      if d2 < nearestDistance
        nearest = centroid
        nearestDistance = d2
    nearest

  getIndexOf: (points, p1) ->
    for p2, i in points
      if p2.x is p1.x and p2.y is p1.y and p2.clusterIndex is p1.clusterIndex
        return i
    -1
    
  setClusterIndex: (point, newClusterIndex) ->
    point.clusterIndex = newClusterIndex

  getDistance: (pos1, pos2) ->
    return Math.sqrt(Math.pow(pos2.x - pos1.x, 2) + Math.pow(pos2.y - pos1.y, 2))
  
  getWeightedIndex: (probabilities) ->
    console.log "Got probabilities = ",probabilities
    if probabilities.length is not @nrPoints
      console.log "Wrong probabilities , ending ... "
      @say "I feel a disturbance in the force! (#{probabilities.length} points instead of #{@nrPoints})"
      @world.endWorld(false, 2)
    
    probs = []
    for i in [0 ... probabilities.length]
        for j in [0 ... (probabilities[i] * 100)]
            probs.push i
    
    r = @randomPool.shift() ? @world.rand.randf()
    console.log "probs is " , probs , "returned index is ",Math.floor(r * probs.length)
    console.log "getWeightedIndex is returning " , probs[Math.floor(r * probs.length)]
    return probs[Math.floor(r * probs.length)]
