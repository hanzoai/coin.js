import 'shop.js/src/utils/patches'

import El           from 'el.js/src'
import Promise      from 'broken'
import objectAssign from 'es-object-assign'
import refer        from 'referential'
import store        from 'akasha'
import Hanzo        from 'hanzo.js/src/browser'

# Monkey Patch common utils onto every View/Instance
import { renderUICurrencyFromJSON } from 'shop.js-util/src/currency'
import { renderDate, rfc3339 } from 'shop.js-util/src/dates'

# Containers
import Deposit                 from 'shop.js/src/deposit'
import Login                   from 'shop.js/src/login'
import Profile                 from 'shop.js/src/profile'
import Register                from 'shop.js/src/register'
import RegisterComplete        from 'shop.js/src/register-complete'
import ResetPassword           from 'shop.js/src/reset-password'
import ResetPasswordComplete   from 'shop.js/src/reset-password-complete'

import {
  Control
  Copy
  Text
  TextBox
  CheckBox
  QRCode
  Select
  QuantitySelect
  CountrySelect
  Currency
  StateSelect
  UserEmail
  UserName
  UserCurrentPassword
  UserPassword
  UserPasswordConfirm
  UserUsername
  ShippingAddressName
  ShippingAddressLine1
  ShippingAddressLine2
  ShippingAddressCity
  ShippingAddressPostalCode
  ShippingAddressState
  ShippingAddressCountry
  CardName
  CardNumber
  CardExpiry
  CardCVC
  Terms
  GiftToggle
  GiftType
  GiftEmail
  GiftMessage
  PromoCode
} from 'shop.js/src/controls'

import m      from '.shop.js/src/mediator'
import Events from './events'

Containers =
  # User Profile
  Login:   Login
  Profile: Profile
  Deposit: Deposit

  # Registration
  Register:         Register
  RegisterComplete: RegisterComplete

  # Reset Password
  ResetPassword:         ResetPassword
  ResetPasswordComplete: ResetPasswordComplete

Controls =
  # Basic
  Control:  Control
  Text:     Text
  TextBox:  TextBox
  Checkbox: CheckBox
  Select:   Select

  # Advanced
  QuantitySelect: QuantitySelect

  # User
  UserEmail:            UserEmail
  UserName:             UserName
  UserCurrentPassword:  UserCurrentPassword
  UserPassword:         UserPassword
  UserPasswordConfirm:  UserPasswordConfirm

  # Shipping Address
  ShippingAddressName:          ShippingAddressName
  ShippingAddressLine1:         ShippingAddressLine1
  ShippingAddressLine2:         ShippingAddressLine2
  ShippingAddressCity:          ShippingAddressCity
  ShippingAddressPostalCode:    ShippingAddressPostalCode
  ShippingAddressState:         ShippingAddressState
  ShippingAddressCountry:       ShippingAddressCountry

  # Card
  CardName:     CardName
  CardNumber:   CardNumber
  CardExpiry:   CardExpiry
  CardCVC:      CardCVC

Coin =
  Controls:   Controls
  Containers: Containers
  Widgets:    {}

Coin.start = ->
  @mount()

Coin.mount = ->
  # create list of elements to mount
  searchQueue     = [document.body]
  elementsToMount = []

  # move to El
  loop
    if searchQueue.length == 0
      break

    root = searchQueue.shift()

    if !root?
      continue

    if root.tagName? && root.tagName in tagNames
      elementsToMount.push root
    else if root.children?.length > 0
      children = Array.prototype.slice.call root.children
      children.unshift 0
      children.unshift searchQueue.length
      searchQueue.splice.apply searchQueue, children

  # mount
  tags = El.mount elementsToMount,
    client:   @client
    data:     @data
    mediator: m

    renderCurrency: renderUICurrencyFromJSON
    renderDate:     renderDate

  ps = []
  for tag in tags
    p = new Promise (resolve) ->
      tag.one 'updated', ->
        resolve()
    ps.push p

  Promise.settle(ps).then ->
    requestAnimationFrame ->
      tagSelectors = tagNames.join ', '
      for tag in tags
        $(tag.root)
          .addClass 'ready'
          .find tagSelectors
          .addClass 'ready'

      m.trigger Events.Ready
    #try to deal with long running stuff
    El.scheduleUpdate()
  .catch (err) ->
    window?.Raven?.captureException err

  return tags

# Deal with mounting procedure for only Coin.js components
tagNames = []
for k, v of Coin.Containers
  tagNames.push(v::tag.toUpperCase()) if v::tag?
for k, v of Coin.Widgets
  tagNames.push(v::tag.toUpperCase()) if v::tag?

# Support inline load
if document?.currentScript?
  key = document.currentScript.getAttribute('data-key')
  endpoint = document.currentScript.getAttribute('data-endpoint')

  if key
    opts =
      key: key

    if endpoint
      opts.endpoint = endpoint

    requestAnimationFrame ()->
      Coin.start opts

if window?
  window.Coin = Coin

export default Coin


