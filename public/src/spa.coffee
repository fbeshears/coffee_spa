#spa.coffee


initModule = ($container) ->
  spa.data.initModule()
  spa.model.initModule()
  spa.shell.initModule($container)
  return

@spa = {
  initModule
}

