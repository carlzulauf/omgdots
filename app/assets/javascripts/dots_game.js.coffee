class @DotsGame
  constructor: (@id) ->
    console.log ["initialized game", @]
    @subscribe()

  subscribe: ->
    options =
      channel: "DotsGameChannel"
      id: @id
    @channel = App.cable.subscriptions.create options,
      received: (data) ->
        console.log ["received", data]

      connected: ->
        console.log ["connected", arguments]

      subscribed: ->
        console.log ["subscribed", arguments]
