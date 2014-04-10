
getPeopleList =  () ->
  people_list = [
    { 
      name : 'Betty', _id: 'id_01',
      css_map: { 
        top: 20, left: 20,
        'background-color': 'rgb( 128, 128, 128)'
      }
    },
    { 
      name: 'Mike',  _id: 'id_02',
      css_map: { 
        top: 60, left: 20,
        'background-color': 'rgb( 128, 255, 128)'
      }
    },
    { 
      name: 'Pebbles', _id: 'id_03',
      css_map: { 
        top: 100, left: 20,
        'background-color': 'rgb( 128, 192, 192)'
      }
    },
    { 
      name: 'Wilma',  _id: 'id_04',
      css_map: { 
        top: 140, left: 20,
        'background-color': 'rgb( 192, 128, 128)'
      }
    }
  ]

  return people_list

test7 = ->

  pl = getPeopleList()
  console.log pl

test6 = ->
  a = 5
  b = 6

  # has to be all on one line
  c = if a > b  then 'bad'  else 'good'

  console.log c 
  return

test5 = ->
  sayhi = ->
    console.log "hello world"

  sayhi() if true

  return


get_arg_map = ->
  return {
    name: 'fred'
    job: 'programmer'
  }

test4 = ->
  pmap = (arg_map) ->
    for own k, v of arg_map
      console.log "#{k}: #{v}"

  # prints arg_map
  pmap  {
    name: 'fred'
    job: 'programmer'
  }

test3 = ->
  name = myname
  
test2 = ->
  name = 'fred'

  name = 'george' if not name?

  console.log name

test1 = ->
  t = get_arg_map()

  for k, v of t

    console.log(k + ":" + v) if k[0] == 'j'

test7()