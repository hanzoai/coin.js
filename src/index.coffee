import 'shop.js/src/utils/patches'

import El           from 'el.js/src'
import Promise      from 'broken'
import objectAssign from 'es-object-assign'
import refer        from 'referential'
import store        from 'akasha'
import Hanzo        from 'hanzo.js/src/browser'
import {Cart}       from 'commerce.js/src'
import Web3         from 'web3'

import {
  getQueries,
  getReferrer,
  getMCIds
} from 'shop.js-util/src/uri'

# Containers
import Deposit                 from 'shop.js/src/containers/deposit'
import Login                   from 'shop.js/src/containers/login'
import Profile                 from 'shop.js/src/containers/profile'
import Register                from 'shop.js/src/containers/register'
import RegisterComplete        from 'shop.js/src/containers/register-complete'
import ResetPassword           from 'shop.js/src/containers/reset-password'
import ResetPasswordComplete   from 'shop.js/src/containers/reset-password-complete'
import ThankYou                from 'shop.js/src/containers/thankyou'

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

import {
  ReCaptcha
} from 'el-controls/src/controls/recaptcha'

import m      from './mediator'
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

  # Thank You
  ThankYou: ThankYou

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

import { renderUICurrencyFromJSON } from 'shop.js-util/src/currency'
import { renderDate, rfc3339 } from 'shop.js-util/src/dates'
import { renderCryptoQR } from 'shop.js-util/src/qrcodes'

Api = Hanzo.Api

Coin =
  Controls:   Controls
  Containers: Containers
  Widgets:    {}
  El:         El

# initialize the data schema
initData = (opts)->
  queries = getQueries()

  referrer = ''
  referrer = getReferrer(opts.config?.hashReferrer) ? opts.order?.referrer
  store.set 'referrer', referrer

  items  = store.get 'items'
  cartId = store.get 'cartId'
  meta   = store.get 'order.metadata'

  d =
    countries:      []
    tokenId:        queries.tokenid
    terms:          opts.terms ? false
    order:
      giftType:     'physical'
      type:         opts.processor ? opts.order?.type ? 'stripe'
      shippingRate: opts.config?.shippingRate   ? opts.order?.shippingRate  ? 0
      taxRate:      opts.config?.taxRate        ? opts.order?.taxRate       ? 0
      currency:     opts.config?.currency       ? opts.order?.currency      ? 'eth'
      referrerId:   referrer
      discount:    0
      tax:         0
      subtotal:     opts.order?.subtotal ? 0
      total:       0
      mode:        opts.mode ? opts.order?.mode ? ''
      items:       items                    ? []
      cartId:      cartId                   ? null
      checkoutUrl: opts.config?.checkoutUrl ? null
      metadata:    meta                     ? {}
    user: null
    payment:
      type: opts.processor ? 'ethereum'

    eth: opts.eth

  for k, v of opts
    unless d[k]?
      d[k] = opts[k]
    else
      for k2, v2 of d[k]
        unless v2?
          d[k][k2] = opts[k]?[k2]

  data = refer d

  return data

# initialize hanzo.js client
initClient = (opts)->
  settings = {}
  settings.key      = opts.key      if opts.key
  settings.endpoint = opts.endpoint if opts.endpoint

  return new Api settings

# initialize rate data
initRates = (client, data)->
  # fetch library data
  lastChecked   = store.get 'lastChecked'
  countries     = store.get('countries') ? []
  taxRates      = store.get 'taxRates'
  shippingRates = store.get 'shippingRates'

  data.set 'countries', countries
  data.set 'taxRates', taxRates
  data.set 'shippingRates', shippingRates

  lastChecked = renderDate(new Date(), rfc3339)

  return client.library.shopjs(
    hasCountries:       !!countries && countries.length != 0
    hasTaxRates:        !!taxRates
    hasShippingRates:   !!shippingRates
    lastChecked:        renderDate(lastChecked || '2000-01-01', rfc3339)
  ).then (res) ->
    countries = res.countries ? countries
    taxRates = res.taxRates ? taxRates
    shippingRates = res.shippingRates ? shippingRates

    store.set 'countries', countries
    store.set 'taxRates', taxRates
    store.set 'shippingRates', shippingRates
    store.set 'lastChecked', lastChecked

    data.set 'countries', countries
    data.set 'taxRates', taxRates
    data.set 'shippingRates', shippingRates

    if res.currency
      data.set 'order.currency', res.currency

    El.scheduleUpdate()

# initialize the cart from commerce.js
initCart = (client, data)->
  cart = new Cart client, data

  cart.onCart = ->
    store.set 'cartId', data.get 'order.cartId'
    [_, mcCId] = getMCIds()
    cart =
      mailchimp:
        checkoutUrl: data.get 'order.checkoutUrl'
      currency: data.get 'order.currency'

    if mcCId
      cart.mailchimp.campaignId = mcCId

    # try get userId
    client.account.get().then (res) ->
      cart._cartUpdate
        email:  res.email
        userId: res.email
    .catch ->
      # ignore error, does not matter

  cart.onUpdate = (item) ->
    items = data.get 'order.items'
    store.set 'items', items

    cart._cartUpdate
      tax:   data.get 'order.tax'
      total: data.get 'order.total'

    if item?
      m.trigger Events.UpdateItem, item

    meta = data.get 'order.metadata'
    store.set 'order.metadata', meta

    cart.invoice()
    El.scheduleUpdate()

  return cart

# initialize mediator with built in cart events
initMediator = (data, cart) ->
  # initialize mediator
  m.on Events.Started, (data) ->
    cart.invoice()
    El.scheduleUpdate()

  m.on Events.DeleteLineItem, (item) ->
    id = item.get 'id'
    if !id
      id = item.get 'productId'
    if !id
      id = item.get 'productSlug'
    Shop.setItem id, 0

  m.on 'error', (err) ->
    console.log err
    window?.Raven?.captureException err

  return m

initWeb3 = (opts = {}) ->
  ethNode = opts?.eth?.node

  if !ethNode
    return web3

  if typeof web3 !== 'undefined'
    web3 = new Web3(web3.currentProvider)
  else
    # set the provider you want from Web3.providers
    web3 = new Web3(new Web3.providers.HttpProvider(ethNode))

  return web3

Coin.start = (opts = {}) ->
  unless opts.key?
    throw new Error 'Please specify your API Key'

  # initialize everything
  @data     = initData opts
  @client   = initClient opts
  @web3     = initWeb3 opts

  @cart     = initCart @client, @data
  @m        = initMediator @data, @cart
  p         = initRates @client, @data

  [tags, ps] = @mount()

  ps.push p

  # Wait until all processing is done before issuing Ready event
  # This is different from Shop.js
  # Shop.js needs to be updated to do it this way
  p = Promise.settle(ps).then ->
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
    cart:     @cart
    client:   @client
    data:     @data
    web3:     @web3
    mediator: m

    renderCurrency: renderUICurrencyFromJSON
    renderDate:     renderDate
    renderCryptoQR: renderCryptoQR

  ps = []
  for tag in tags
    p = new Promise (resolve) ->
      tag.one 'updated', ->
        resolve()
    ps.push p

  El.scheduleUpdate()

  return [tags, ps]

Coin.getWeb3 = ->
  return @web3

Coin.getMediator = ->
  return m

Coin.getData = ->
  return @data

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


