Action = require('./systems/Action')
AI = require('./systems/AI')
Alliance = require('./systems/Alliance')
Collision = require('./systems/Collision')
Combat = require('./systems/Combat')
Display = require('./systems/Display')
Effect = require('./systems/Effect')
Event = require('./systems/Event')
Existence = require('./systems/Existence')
Game = require('./systems/Game')
Hearing = require('./systems/Hearing')
Inventory = require('./systems/Inventory')
Magic = require('./systems/Magic')
Movement = require('./systems/Movement')
Physics = require('./systems/Physics')
Programming = require('./systems/Programming')
Targeting = require('./systems/Targeting')
UI = require('./systems/UI')
Vision = require('./systems/Vision')
Test = require('./systems/Test')

AnnouncesLoops = require('./components/hearing/AnnouncesLoops')
AttacksAtRange = require('./components/combat/AttacksAtRange')
Acts = require('./components/action/Acts')
ActsWhenTouched = require('./components/collision/ActsWhenTouched')
Allied = require('./components/alliance/Allied')
AnnouncesActions = require('./components/hearing/AnnouncesActions')
ArcaneAllyReferee = require('./components/misc/ArcaneAllyReferee')
Arrow = require('./components/combat/Arrow')
ASTParser = require('./components/misc/ASTParser')
Attackable = require('./components/combat/Attackable')
Attacks = require('./components/combat/Attacks')
AttacksNearby = require('./components/combat/AttacksNearby')
AttacksSelf = require('./components/ai/AttacksSelf')
Aura = require('./components/display/Aura')
AutoCasts = require('./components/ai/AutoCasts')
AutoTargetsNearest = require('./components/ai/AutoTargetsNearest')
AutoTargetsStrongest = require('./components/ai/AutoTargetsStrongest')
AvoidsEnemies = require('./components/ai/AvoidsEnemies')
Backstabs = require('./components/combat/Backstabs')
BackwoodsAmbushReferee = require('./components/misc/BackwoodsAmbushReferee')
BackwoodsTreasureReferee = require('./components/misc/BackwoodsTreasureReferee')
Bashes = require('./components/combat/Bashes')
Beam = require('./components/combat/Beam')
BearTrap = require('./components/combat/BearTrap')
Berserks = require('./components/combat/Berserks')
Blinks = require('./components/movement/Blinks')
Bobs = require('./components/display/Bobs')
BonemenderReferee = require('./components/misc/BonemenderReferee')
BoulderWoodsReferee = require('./components/misc/BoulderWoodsReferee')
BreakoutReferee = require('./components/misc/BreakoutReferee')
Builds = require('./components/existence/Builds')
CaptureTheFlag = require('./components/misc/CaptureTheFlag')
CarriesUnit = require('./components/movement/CarriesUnit')
Carryable = require('./components/inventory/Carryable')
Casts = require('./components/magic/Casts')
CastsAntigravity = require('./components/magic/CastsAntigravity')
CastsChainLightning = require('./components/magic/CastsChainLightning')
CastsConfuse = require('./components/magic/CastsConfuse')
CastsDisintegrate = require('./components/magic/CastsDisintegrate')
CastsDispel = require('./components/magic/CastsDispel')
CastsDrainLife = require('./components/magic/CastsDrainLife')
CastsEarthskin = require('./components/magic/CastsEarthskin')
CastsFear = require('./components/magic/CastsFear')
CastsFireball = require('./components/magic/CastsFireball')
CastsFlameArmor = require('./components/magic/CastsFlameArmor')
CastsFling = require('./components/magic/CastsFling')
CastsForceBolt = require('./components/magic/CastsForceBolt')
CastsGoldstorm = require('./components/magic/CastsGoldstorm')
CastsGrow = require('./components/magic/CastsGrow')
CastsHaste = require('./components/magic/CastsHaste')
CastsHeal = require('./components/magic/CastsHeal')
CastsIceRink = require('./components/magic/CastsIceRink')
CastsInvisibility = require('./components/magic/CastsInvisibility')
CastsLightningBolt = require('./components/magic/CastsLightningBolt')
CastsMagicMissile = require('./components/magic/CastsMagicMissile')
CastsPoisonCloud = require('./components/magic/CastsPoisonCloud')
CastsRaiseDead = require('./components/magic/CastsRaiseDead')
CastsRegen = require('./components/magic/CastsRegen')
CastsRoot = require('./components/magic/CastsRoot')
CastsSacrifice = require('./components/magic/CastsSacrifice')
CastsShockwave = require('./components/magic/CastsShockwave')
CastsShrink = require('./components/magic/CastsShrink')
CastsSlow = require('./components/magic/CastsSlow')
CastsSoulLink = require('./components/magic/CastsSoulLink')
CastsSummonBurl = require('./components/magic/CastsSummonBurl')
CastsSummonFangrider = require('./components/magic/CastsSummonFangrider')
CastsSummonUndead = require('./components/magic/CastsSummonUndead')
CastsSwap = require('./components/magic/CastsSwap')
CastsTeleport = require('./components/magic/CastsTeleport')
CastsTestSpells = require('./components/magic/CastsTestSpells')
CastsTimeWarp = require('./components/magic/CastsTimeWarp')
CastsWindstorm = require('./components/magic/CastsWindstorm')
CatchesArrows = require('./components/combat/CatchesArrows')
CatsyncTowerReferee = require('./components/misc/CatsyncTowerReferee')
CavernReferee = require('./components/misc/CavernReferee')
CavernSurvival2Referee = require('./components/misc/CavernSurvival2Referee')
Charms = require('./components/combat/Charms')
Chases = require('./components/combat/Chases')
ChasesAndAttacks = require('./components/ai/ChasesAndAttacks')
Chieftains = require('./components/ai/Chieftains')
ClashOfClonesReferee = require('./components/misc/ClashOfClonesReferee')
Cleaves = require('./components/combat/Cleaves')
CoinMagnet = require('./components/inventory/CoinMagnet')
CoinucopiaReferee = require('./components/misc/CoinucopiaReferee')
ColdBlast = require('./components/combat/ColdBlast')
Collectable = require('./components/inventory/Collectable')
Collects = require('./components/inventory/Collects')
Collides = require('./components/collision/Collides')
Colored = require('./components/display/Colored')
ColoredTileMazePlayer = require('./components/misc/ColoredTileMazePlayer')
Commands = require('./components/programming/Commands')
Container = require('./components/inventory/Container')
ControlPoints = require('./components/misc/ControlPoints')
CopperMeadowsReferee = require('./components/misc/CopperMeadowsReferee')
CragTagReferee = require('./components/misc/CragTagReferee')
CrissCrossPlayer = require('./components/misc/CrissCrossPlayer')
CupboardsOfKithgardReferee = require('./components/misc/CupboardsOfKithgardReferee')
DarkElement = require('./components/combat/DarkElement')
Darkness = require('./components/vision/Darkness')
Dashes = require('./components/movement/Dashes')
Debugs = require('./components/programming/Debugs')
Decoy = require('./components/targeting/Decoy')
DefaultPet = require('./components/ai/DefaultPet')
DesertReferee = require('./components/misc/DesertReferee')
CrissCrossReferee = require('./components/misc/CrissCrossReferee')
DeadlyDungeonRescueReferee = require('./components/misc/DeadlyDungeonRescueReferee')
DeadlyPursuitReferee = require('./components/misc/DeadlyPursuitReferee')
DefaultPetAttacks = require('./components/ai/DefaultPetAttacks')
Defends = require('./components/ai/Defends')
DefenseOfPlainswoodReferee = require('./components/misc/DefenseOfPlainswoodReferee')
DelaysExistence = require('./components/existence/DelaysExistence')
DestroyHandler = require('./components/game/DestroyHandler')
DestroyingAngelReferee = require('./components/misc/DestroyingAngelReferee')
DetectsOgres = require('./components/misc/DetectsOgres')
Devours = require('./components/combat/Devours')
DialoguesReferee = require('./components/misc/DialoguesReferee')
Directional = require('./components/physics/Directional')
DirectionalMoves = require('./components/movement/DirectionalMoves')
Distracts = require('./components/action/Distracts')
DrawsBounds = require('./components/display/DrawsBounds')
DropTheFlagReferee = require('./components/misc/DropTheFlagReferee')
DustReferee = require('./components/misc/DustReferee')
Electrocutes = require('./components/combat/Electrocutes')
Envenoms = require('./components/combat/Envenoms')
Equips = require('./components/inventory/Equips')
Exists = require('./components/existence/Exists')
Expires = require('./components/existence/Expires')
ExplosiveRing = require('./components/combat/ExplosiveRing')
Fetches = require('./components/inventory/Fetches')
FieryTrapReferee = require('./components/misc/FieryTrapReferee')
FightsBack = require('./components/ai/FightsBack')
FindsPaths = require('./components/ai/FindsPaths')
Flaps = require('./components/combat/Flaps')
Flocking = require('./components/misc/Flocking')
FollowsNearest = require('./components/ai/FollowsNearest')
FollowsNearestEnemy = require('./components/ai/FollowsNearestEnemy')
FollowsNearestFriend = require('./components/ai/FollowsNearestFriend')
ForceBolt = require('./components/combat/ForceBolt')
ForcePushes = require('./components/action/ForcePushes')
FreezingBackstabs = require('./components/combat/FreezingBackstabs')
GameEnvironment = require('./components/game/GameEnvironment')
GameInput = require('./components/game/GameInput')
GameMechanics = require('./components/game/GameMechanics')
GameProperties = require('./components/game/GameProperties')
GameReferee = require('./components/game/GameReferee')
GameSnippets = require('./components/game/GameSnippets')
GameSpawns = require('./components/game/GameSpawns')
GameUI = require('./components/game/GameUI')
GegaTrialsReferee = require('./components/misc/GegaTrialsReferee')
GivesInstructions = require('./components/ai/GivesInstructions')
Goal = require('./components/misc/Goal')
GravityVortexThang = require('./components/combat/GravityVortexThang')
GridmancerRectangles = require('./components/display/GridmancerRectangles')
GrowsFlowers = require('./components/existence/GrowsFlowers')
HackAndDashReferee = require('./components/misc/HackAndDashReferee')
HarrowlandReferee = require('./components/misc/HarrowlandReferee')
HasAPI = require('./components/programming/HasAPI')
HasEffects = require('./components/effect/HasEffects')
HasEvents = require('./components/event/HasEvents')
HasPet = require('./components/existence/HasPet')
Hatches = require('./components/existence/Hatches')
HeadHunts = require('./components/ai/HeadHunts')
Heals = require('./components/combat/Heals')
Hears = require('./components/hearing/Hears')
HearsAndAggros = require('./components/ai/HearsAndAggros')
HearsAndObeys = require('./components/ai/HearsAndObeys')
Hides = require('./components/targeting/Hides')
HoardingGoldReferee = require('./components/misc/HoardingGoldReferee')
HoldTheForestPass = require('./components/misc/HoldTheForestPass')
HurlsEnemies = require('./components/combat/HurlsEnemies')
HurtsToTouch = require('./components/combat/HurtsToTouch')
IllusoryInterruptionReferee = require('./components/misc/IllusoryInterruptionReferee')
Impales = require('./components/combat/Impales')
Invisible = require('./components/display/Invisible')
Item = require('./components/inventory/Item')
Jitters = require('./components/movement/Jitters')
JumpsForeverAndEver = require('./components/ai/JumpsForeverAndEver')
JumpsStraightUp = require('./components/movement/JumpsStraightUp')
JumpsTooMuch = require('./components/ai/JumpsTooMuch')
JumpsToTarget = require('./components/movement/JumpsToTarget')
KeepingTimeReferee = require('./components/misc/KeepingTimeReferee')
KingOfHillAPI = require('./components/misc/KingOfHillAPI')
KithgardBrawlReferee = require('./components/misc/KithgardBrawlReferee')
KMeansReferee = require('./components/misc/KMeansReferee')
Land = require('./components/movement/Land')
Layers = require('./components/display/Layers')
LaysMines = require('./components/combat/LaysMines')
LighterFareReferee = require('./components/misc/LighterFareReferee')
Lightstone = require('./components/inventory/Lightstone')
LimitsExecution = require('./components/programming/LimitsExecution')
Locked = require('./components/inventory/Locked')
LurkersReferee = require('./components/misc/LurkersReferee')
MadMaxerGetsGreedyReferee = require('./components/misc/MadMaxerGetsGreedyReferee')
MadMaxerRedemptionReferee = require('./components/misc/MadMaxerRedemptionReferee')
MadMaxerReferee = require('./components/misc/MadMaxerReferee')
MadMaxerSellsOutReferee = require('./components/misc/MadMaxerSellsOutReferee')
MadMaxerStrikesBackReferee = require('./components/misc/MadMaxerStrikesBackReferee')
ManaBlasts = require('./components/combat/ManaBlasts')
MarchingOrders = require('./components/misc/MarchingOrders')
MedicalAttentionReferee = require('./components/misc/MedicalAttentionReferee')
Mine = require('./components/combat/Mine')
MinesweeperReferee = require('./components/misc/MinesweeperReferee')
Missile = require('./components/combat/Missile')
ModSquad = require('./components/misc/ModSquad')
MonsterGenerator = require('./components/game/MonsterGenerator')
MountainMercenariesReferee = require('./components/misc/MountainMercenariesReferee')
Moves = require('./components/movement/Moves')
MovesConstantly = require('./components/movement/MovesConstantly')
MovesSimply = require('./components/movement/MovesSimply')
MunchkinHarvestReferee = require('./components/misc/MunchkinHarvestReferee')
MunchkinSwarmReferee = require('./components/misc/MunchkinSwarmReferee')
OasisReferee = require('./components/misc/OasisReferee')
OddSandstormReferee = require('./components/misc/OddSandstormReferee')
Openable = require('./components/action/Openable')
Patrols = require('./components/movement/Patrols')
PatrolsAndAttacks = require('./components/ai/PatrolsAndAttacks')
PaysBounty = require('./components/inventory/PaysBounty')
PeasantProtectionReferee = require('./components/misc/PeasantProtectionReferee')
PeskyYaksReferee = require('./components/misc/PeskyYaksReferee')
PhaseShifts = require('./components/movement/PhaseShifts')
Physical = require('./components/physics/Physical')
PlanReferee = require('./components/misc/PlanReferee')
Plans = require('./components/programming/Plans')
Player = require('./components/movement/Player')
PongArenaAPI = require('./components/misc/PongArenaAPI')
PowersUp = require('./components/combat/PowersUp')
PreferentialTreatmentReferee = require('./components/misc/PreferentialTreatmentReferee')
Programmable = require('./components/programming/Programmable')
Projectile = require('./components/combat/Projectile')
PropertyErrorHelper = require('./components/misc/PropertyErrorHelper')
ProximityTrigger = require('./components/collision/ProximityTrigger')
QuickSortReferee = require('./components/misc/QuickSortReferee')
RadiantAuraReferee = require('./components/misc/RadiantAuraReferee')
Rains = require('./components/existence/Rains')
RangeFinderReferee = require('./components/misc/RangeFinderReferee')
RazorDisc = require('./components/combat/RazorDisc')
ReducesCooldowns = require('./components/action/ReducesCooldowns')
Referee = require('./components/misc/Referee')
Reflects = require('./components/combat/Reflects')
ResetsCooldowns = require('./components/action/ResetsCooldowns')
RotatesToTarget = require('./components/targeting/RotatesToTarget')
RunnerArenaAPI = require('./components/misc/RunnerArenaAPI')
RunsAway = require('./components/ai/RunsAway')
RunsInCircles = require('./components/ai/RunsInCircles')
SacredStatueReferee = require('./components/misc/SacredStatueReferee')
SarvenBrawlReferee = require('./components/misc/SarvenBrawlReferee')
SarvenGapsReferee = require('./components/misc/SarvenGapsReferee')
SarvenRescueReferee = require('./components/misc/SarvenRescueReferee')
SarvenRoadReferee = require('./components/misc/SarvenRoadReferee')
SarvenSaviorReferee = require('./components/misc/SarvenSaviorReferee')
SarvenSentryReferee = require('./components/misc/SarvenSentryReferee')
SarvenShepherdReferee = require('./components/misc/SarvenShepherdReferee')
SarvenTreasureReferee = require('./components/misc/SarvenTreasureReferee')
Says = require('./components/hearing/Says')
Scales = require('./components/ui/Scales')
Scampers = require('./components/ai/Scampers')
Scattershots = require('./components/combat/Scattershots')
Sees = require('./components/vision/Sees')
Selectable = require('./components/ui/Selectable')
ShadowVortex = require('./components/combat/ShadowVortex')
ShapeShifts = require('./components/existence/ShapeShifts')
Shell = require('./components/combat/Shell')
ShieldBubbles = require('./components/combat/ShieldBubbles')
Shields = require('./components/combat/Shields')
ShineGetterReferee = require('./components/misc/ShineGetterReferee')
Shoots = require('./components/combat/Shoots')
Shoveable = require('./components/movement/Shoveable')
ShowsName = require('./components/display/ShowsName')
ShowsText = require('./components/display/ShowsText')
ShrapnelReferee = require('./components/misc/ShrapnelReferee')
SiegeOfStoneholdReferee = require('./components/misc/SiegeOfStoneholdReferee')
SignsAndPortentsReferee = require('./components/misc/SignsAndPortentsReferee')
SkySpanBridge = require('./components/misc/SkySpanBridge')
Slams = require('./components/combat/Slams')
SpamAttack = require('./components/combat/SpamAttack')
Spawns = require('./components/existence/Spawns')
SpawnsRectangles = require('./components/display/SpawnsRectangles')
SteeringSteers = require('./components/misc/SteeringSteers')
Sticky = require('./components/movement/Sticky')
Stomps = require('./components/combat/Stomps')
StonewallWarcry = require('./components/combat/StonewallWarcry')
StormingTheTowersOfArethReferee = require('./components/misc/StormingTheTowersOfArethReferee')
StoryReferee = require('./components/misc/StoryReferee')
StrandedInTheDunesReferee = require('./components/misc/StrandedInTheDunesReferee')
SuicideExplosion = require('./components/combat/SuicideExplosion')
SwiftDaggerReferee = require('./components/misc/SwiftDaggerReferee')
TalksToSelf = require('./components/ai/TalksToSelf')
Targets = require('./components/targeting/Targets')
Team = require('./components/alliance/Team')
Teleports = require('./components/movement/Teleports')
Terrifies = require('./components/combat/Terrifies')
TestComponent = require('./components/action/TestComponent')
TestReferee = require('./components/misc/TestReferee')
TheDunesReferee = require('./components/misc/TheDunesReferee')
TheGreatYakStampedeReferee = require('./components/misc/TheGreatYakStampedeReferee')
TheMightySandYakReferee = require('./components/misc/TheMightySandYakReferee')
ThePrisonerReferee = require('./components/misc/ThePrisonerReferee')
TheTrialsReferee = require('./components/misc/TheTrialsReferee')
ThornbushFarmReferee = require('./components/misc/ThornbushFarmReferee')
Throws = require('./components/combat/Throws')
ThrowsEnemies = require('./components/combat/ThrowsEnemies')
ThunderhoovesReferee = require('./components/misc/ThunderhoovesReferee')
TicTacToeReferee = require('./components/misc/TicTacToeReferee')
Tinted = require('./components/ui/Tinted')
TouchOfDeathReferee = require('./components/misc/TouchOfDeathReferee')
TowerBreakoutPlayer = require('./components/misc/TowerBreakoutPlayer')
TracksTime = require('./components/existence/TracksTime')
TreasureCaveReferee = require('./components/misc/TreasureCaveReferee')
TreasureGroveReferee = require('./components/misc/TreasureGroveReferee')
Tricks = require('./components/action/Tricks')
UserCodeAnalyser = require('./components/misc/UserCodeAnalyser')
UsesArray = require('./components/programming/UsesArray')
UsesDate = require('./components/programming/UsesDate')
UsesFunction = require('./components/programming/UsesFunction')
UsesGlobals = require('./components/programming/UsesGlobals')
UsesHTML = require('./components/programming/UsesHTML')
UsesJQuery = require('./components/programming/UsesJQuery')
UsesJSON = require('./components/programming/UsesJSON')
UsesLoDash = require('./components/programming/UsesLoDash')
UsesMath = require('./components/programming/UsesMath')
UsesNumber = require('./components/programming/UsesNumber')
UsesObject = require('./components/programming/UsesObject')
UsesPetSnippets = require('./components/programming/UsesPetSnippets')
UsesRegExp = require('./components/programming/UsesRegExp')
UsesSnippets = require('./components/programming/UsesSnippets')
UsesString = require('./components/programming/UsesString')
UsesVector = require('./components/programming/UsesVector')
UsesWebJavaScript = require('./components/programming/UsesWebJavaScript')
UsesWebJavaScriptSnippets = require('./components/programming/UsesWebJavaScriptSnippets')
VillageGuardReferee = require('./components/misc/VillageGuardReferee')
Waits = require('./components/action/Waits')
WallOfDarkness = require('./components/combat/WallOfDarkness')
WarCries = require('./components/combat/WarCries')
Waypoints = require('./components/targeting/Waypoints')
WildHorsesReferee = require('./components/misc/WildHorsesReferee')
WoodlandCleaverReferee = require('./components/misc/WoodlandCleaverReferee')
WorldCoordinates = require('./components/ui/WorldCoordinates')
WorldExpires = require('./components/existence/WorldExpires')
WorldPaths = require('./components/ui/WorldPaths')
WorldZoom = require('./components/ui/WorldZoom')
YakstractionReferee = require('./components/misc/YakstractionReferee')

loadSystems = ()->
    systems = {
        Action,
        AI,
        Alliance,
        Collision,
        Combat,
        Display,
        Effect,
        Event,
        Existence,
        Game,
        Hearing,
        Inventory,
        Magic,
        Movement,
        Physics,
        Programming,
        Targeting,
        UI,
        Vision,
        Test
    }
    for k, v of systems
        v.className = k
    return systems

loadComponents = () ->
    components = {
        AnnouncesLoops,
        AttacksAtRange,
        Acts,
        ActsWhenTouched,
        Allied,
        AnnouncesActions,
        ArcaneAllyReferee,
        Arrow,
        ASTParser,
        Attackable,
        Attacks,
        AttacksNearby,
        AttacksSelf,
        Aura,
        AutoCasts,
        AutoTargetsNearest,
        AutoTargetsStrongest,
        AvoidsEnemies,
        Backstabs,
        BackwoodsAmbushReferee,
        BackwoodsTreasureReferee,
        Bashes,
        Beam,
        BearTrap,
        Berserks,
        Blinks,
        Bobs,
        BonemenderReferee,
        BoulderWoodsReferee,
        BreakoutReferee,
        Builds,
        CaptureTheFlag,
        CarriesUnit,
        Carryable,
        Casts,
        CastsAntigravity,
        CastsChainLightning,
        CastsConfuse,
        CastsDisintegrate,
        CastsDispel,
        CastsDrainLife,
        CastsEarthskin,
        CastsFear,
        CastsFireball,
        CastsFlameArmor,
        CastsFling,
        CastsForceBolt,
        CastsGoldstorm,
        CastsGrow,
        CastsHaste,
        CastsHeal,
        CastsIceRink,
        CastsInvisibility,
        CastsLightningBolt,
        CastsMagicMissile,
        CastsPoisonCloud,
        CastsRaiseDead,
        CastsRegen,
        CastsRoot,
        CastsSacrifice,
        CastsShockwave,
        CastsShrink,
        CastsSlow,
        CastsSoulLink,
        CastsSummonBurl,
        CastsSummonFangrider,
        CastsSummonUndead,
        CastsSwap,
        CastsTeleport,
        CastsTestSpells,
        CastsTimeWarp,
        CastsWindstorm,
        CatchesArrows,
        CatsyncTowerReferee,
        CavernReferee,
        CavernSurvival2Referee,
        Charms,
        Chases,
        ChasesAndAttacks,
        Chieftains,
        ClashOfClonesReferee,
        Cleaves,
        CoinMagnet,
        CoinucopiaReferee,
        ColdBlast,
        Collectable,
        Collects,
        Collides,
        Colored,
        ColoredTileMazePlayer,
        Commands,
        Container,
        ControlPoints,
        CopperMeadowsReferee,
        CragTagReferee,
        CrissCrossPlayer,
        CupboardsOfKithgardReferee,
        DarkElement,
        Darkness,
        Dashes,
        Debugs,
        Decoy,
        DefaultPet,
        DesertReferee,
        CrissCrossReferee,
        DeadlyDungeonRescueReferee,
        DeadlyPursuitReferee,
        DefaultPetAttacks,
        Defends,
        DefenseOfPlainswoodReferee,
        DelaysExistence,
        DestroyHandler,
        DestroyingAngelReferee,
        DetectsOgres,
        Devours,
        DialoguesReferee,
        Directional,
        DirectionalMoves,
        Distracts,
        DrawsBounds,
        DropTheFlagReferee,
        DustReferee,
        Electrocutes,
        Envenoms,
        Equips,
        Exists,
        Expires,
        ExplosiveRing,
        Fetches,
        FieryTrapReferee,
        FightsBack,
        FindsPaths,
        Flaps,
        Flocking,
        FollowsNearest,
        FollowsNearestEnemy,
        FollowsNearestFriend,
        ForceBolt,
        ForcePushes,
        FreezingBackstabs,
        GameEnvironment,
        GameInput,
        GameMechanics,
        GameProperties,
        GameReferee,
        GameSnippets,
        GameSpawns,
        GameUI,
        GegaTrialsReferee,
        GivesInstructions,
        Goal,
        GravityVortexThang,
        GridmancerRectangles,
        GrowsFlowers,
        HackAndDashReferee,
        HarrowlandReferee,
        HasAPI,
        HasEffects,
        HasEvents,
        HasPet,
        Hatches,
        HeadHunts,
        Heals,
        Hears,
        HearsAndAggros,
        HearsAndObeys,
        Hides,
        HoardingGoldReferee,
        HoldTheForestPass,
        HurlsEnemies,
        HurtsToTouch,
        IllusoryInterruptionReferee,
        Impales,
        Invisible,
        Item,
        Jitters,
        JumpsForeverAndEver,
        JumpsStraightUp,
        JumpsTooMuch,
        JumpsToTarget,
        KeepingTimeReferee,
        KingOfHillAPI,
        KithgardBrawlReferee,
        KMeansReferee,
        Land,
        Layers,
        LaysMines,
        LighterFareReferee,
        Lightstone,
        LimitsExecution,
        Locked,
        LurkersReferee,
        MadMaxerGetsGreedyReferee,
        MadMaxerRedemptionReferee,
        MadMaxerReferee,
        MadMaxerSellsOutReferee,
        MadMaxerStrikesBackReferee,
        ManaBlasts,
        MarchingOrders,
        MedicalAttentionReferee,
        Mine,
        MinesweeperReferee,
        Missile,
        ModSquad,
        MonsterGenerator,
        MountainMercenariesReferee,
        Moves,
        MovesConstantly,
        MovesSimply,
        MunchkinHarvestReferee,
        MunchkinSwarmReferee,
        OasisReferee,
        OddSandstormReferee,
        Openable,
        Patrols,
        PatrolsAndAttacks,
        PaysBounty,
        PeasantProtectionReferee,
        PeskyYaksReferee,
        PhaseShifts,
        Physical,
        PlanReferee,
        Plans,
        Player,
        PongArenaAPI,
        PowersUp,
        PreferentialTreatmentReferee,
        Programmable,
        Projectile,
        PropertyErrorHelper,
        ProximityTrigger,
        QuickSortReferee,
        RadiantAuraReferee,
        Rains,
        RangeFinderReferee,
        RazorDisc,
        ReducesCooldowns,
        Referee,
        Reflects,
        ResetsCooldowns,
        RotatesToTarget,
        RunnerArenaAPI,
        RunsAway,
        RunsInCircles,
        SacredStatueReferee,
        SarvenBrawlReferee,
        SarvenGapsReferee,
        SarvenRescueReferee,
        SarvenRoadReferee,
        SarvenSaviorReferee,
        SarvenSentryReferee,
        SarvenShepherdReferee,
        SarvenTreasureReferee,
        Says,
        Scales,
        Scampers,
        Scattershots,
        Sees,
        Selectable,
        ShadowVortex,
        ShapeShifts,
        Shell,
        ShieldBubbles,
        Shields,
        ShineGetterReferee,
        Shoots,
        Shoveable,
        ShowsName,
        ShowsText,
        ShrapnelReferee,
        SiegeOfStoneholdReferee,
        SignsAndPortentsReferee,
        SkySpanBridge,
        Slams,
        SpamAttack,
        Spawns,
        SpawnsRectangles,
        SteeringSteers,
        Sticky,
        Stomps,
        StonewallWarcry,
        StormingTheTowersOfArethReferee,
        StoryReferee,
        StrandedInTheDunesReferee,
        SuicideExplosion,
        SwiftDaggerReferee,
        TalksToSelf,
        Targets,
        Team,
        Teleports,
        Terrifies,
        TestComponent,
        TestReferee,
        TheDunesReferee,
        TheGreatYakStampedeReferee,
        TheMightySandYakReferee,
        ThePrisonerReferee,
        TheTrialsReferee,
        ThornbushFarmReferee,
        Throws,
        ThrowsEnemies,
        ThunderhoovesReferee,
        TicTacToeReferee,
        Tinted,
        TouchOfDeathReferee,
        TowerBreakoutPlayer,
        TracksTime,
        TreasureCaveReferee,
        TreasureGroveReferee,
        Tricks,
        UserCodeAnalyser,
        UsesArray,
        UsesDate,
        UsesFunction,
        UsesGlobals,
        UsesHTML,
        UsesJQuery,
        UsesJSON,
        UsesLoDash,
        UsesMath,
        UsesNumber,
        UsesObject,
        UsesPetSnippets,
        UsesRegExp,
        UsesSnippets,
        UsesString,
        UsesVector,
        UsesWebJavaScript,
        UsesWebJavaScriptSnippets,
        VillageGuardReferee,
        Waits,
        WallOfDarkness,
        WarCries,
        Waypoints,
        WildHorsesReferee,
        WoodlandCleaverReferee,
        WorldCoordinates,
        WorldExpires,
        WorldPaths,
        WorldZoom,
        YakstractionReferee,
    }
    for k, v of components
        v.className = k
    return components

module.exports = {
    loadSystems,
    loadComponents
}