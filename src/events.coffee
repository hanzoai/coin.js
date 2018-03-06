import ControlEvents from 'el-controls/src/events'

export default Events =
  # Coin.js is Started
  Started:
    'started'
  # Coin.js is ready to take commands
  Ready:
    'ready'

  Change:        ControlEvents.Change
  ChangeSuccess: ControlEvents.ChangeSuccess
  ChangeFailed:  ControlEvents.ChangeFailed
