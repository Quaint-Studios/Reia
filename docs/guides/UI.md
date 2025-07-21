# UI

This is a guide to help you create UI for this project and maybe your own projects too!

## Understanding the Canvas

Reia has its stretch mode set to `canvas_items` and the aspect is set to `expand`. This gives us the ability to support multiple screen sizes without having to change the UI for them. The only drawback is the UI can't be cluttered or it'll fail. But, that's okay. The UI should be designed to feel *open* yet not empty.

We also use the `Sensor Landscape` orientation setting for handheld devices so you can rotate your phone!

## Components

Commonly used components go in the `common/components` folder. And if a scene has their own custom component, then that component belongs in `scenes/dir_1/dir_2/components/component.tscn`. Any scripts for that component should be named the same as the `.tscn` file. This way we don't need folders to sort out files. And if you need to break up functionality then go ahead and do `component/sub_component.gd`.

### Buttons

We have all buttons set to be stripped of their designs so we can have a blank slate by default. If a button has designs that change when hovered, focused, or pressed then signals is your answer. Attach a script to the button and set up a signal to handle that functionality. It'd be best to also give then unique names so you can access them with `%NodeName`.

### Layouts

TODO...
