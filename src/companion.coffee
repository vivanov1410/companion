$ ->
  $('#datepicker').datepicker()
  #if not $('#country option:selected').length
  #  $('#country option[value]')
  #country_options = $('option', $('#country'))
  $('#country').change ->
    selected = $('#country').val()
    switch selected
      when 'Canada'
        $('#state').html '''
          <option value='State'>State</option>
          <option value='BC'>BC</option>
          <option value='AB'>AB</option>
        '''
      when 'USA'
        $('#state').html '''
          <option value='State'>State</option>
          <option value='WA'>WA</option>
          <option value='NY'>NY</option>
        '''