# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
jQuery ->

  $("#checkbox-header").click ->
    $('.checkbox-list').prop('checked', $('#checkbox-header').prop('checked'))

  $("#delete-btn").click ->
    check_count = $('.checkbox-list:checked').length;
    if check_count == 0
      alert 'no delete target checked'
      return false
    else
      confirm 'delete tasks?'

