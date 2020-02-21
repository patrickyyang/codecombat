const schema = require('./../schemas')

const UserStatsSchema = schema.object({}, {
  userId: schema.objectId({ links: [ { rel: 'extra', href: '/db/user/{($)}' } ] }),
  stats: schema.object(
    {
      title: 'User stats',
      additionalProperties: true
    }
  )
})

schema.extendBasicProperties(UserStatsSchema, 'user.stat')

module.exports = UserStatsSchema
