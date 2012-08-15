$ ->
  $('#datepicker').datepicker()
  $('#datepicker').datepicker 'option', 'dateFormat', 'yy/mm/dd'

  $('#country').change ->
    selected = $('#country').val()
    switch selected
      when 'Canada'
        $('#state').html '''
          <option value='State'>State</option>
          <option value='AB'>AB</option>
          <option value='BC'>BC</option>
          <option value='MB'>MB</option>
          <option value='NB'>NB</option>
          <option value='NL'>NL</option>
          <option value='NS'>NS</option>
          <option value='NT'>NT</option>
          <option value='NU'>NU</option>
          <option value='ON'>ON</option>
          <option value='PE'>PE</option>
          <option value='QC'>QC</option>
          <option value='SK'>SK</option>
          <option value='YT'>YT</option>
        '''
        $('#units').html "<option value='L'>L</option>"

      when 'USA'
        $('#state').html '''
          <option value='State'>State</option>
          <option value='WA'>WA</option>
          <option value='NY'>NY</option>
        '''
        $('#units').html "<option value='Gal'>Gal</option>"

  $('#submit-fuel').click ->
    fuel_receipt =
      type: 'fuel receipt'
      date: new Date Date.parse $('#datepicker').val().replace(/\//g, ' ')
      country: $('#country').val()
      state: $('#state').val()
      quantity: $('#quantity').val()
      units: $('#units').val()

    now.submit_fuel_receipt fuel_receipt

  $('#submit-stop').click ->
    stop =
      type: 'stop'
      date: new Date Date.parse $('#datepicker').val().replace(/\//g, ' ')
      country: $('#country').val()
      state: $('#state').val()
      address: $('#address').val()
      postal_code: $('#postal-code').val()

    now.submit_stop stop

  now.update_fuel_receipts = (receipts) ->
    receipts = receipts.reverse()
    rows = ''
    for receipt in receipts
      date = new Date(receipt.value.date).toLocaleDateString()
      row = """
      <tr>
        <td>#{date}</td>
        <td>#{receipt.value.country}</td>
        <td>#{receipt.value.state}</td>
        <td>#{receipt.value.quantity}</td>
        <td>#{receipt.value.units}</td>
      </tr>
      """
      rows += row
    $('tbody').html rows

  now.update_stops = (stops) ->
    stops = stops.reverse()
    rows = ''
    for stop in stops
      date = new Date(stop.value.date).toLocaleDateString()
      row = """
      <tr>
        <td>#{date}</td>
        <td>#{stop.value.country}</td>
        <td>#{stop.value.state}</td>
        <td>#{stop.value.address}</td>
        <td>#{stop.value.postal_code}</td>
      </tr>
      """
      rows += row
    $('tbody').html rows