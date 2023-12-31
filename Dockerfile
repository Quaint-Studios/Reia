FROM ubuntu:23.10

WORKDIR /app

COPY .scripts .scripts
COPY ./addons ./addons
COPY ./assets ./aseets
COPY ./changelogs ./changelogs
COPY ./fonts ./fonts
COPY ./rsc ./rsc
COPY ./scenes ./scenes
COPY ./scripts ./scripts
COPY ./shaders ./shaders
COPY ./src ./src
COPY ./tests ./tests
COPY ./themes ./themes
COPY ./export_presets.cfg ./export_presets.cfg
COPY ./project.godot ./project.godot

# This doesn't handle errors yet.
# But the setup.sh returns 0 on failure.
RUN bash .scripts/linux/setup.sh

VOLUME .builds/server

# COPY .builds/server/Reia /server
VOLUME .builds/server

ENV PORT=4337
EXPOSE 4337

# In the future we might want to pass params.
# Or grab secure files using a ssh key and move them there.
CMD ['./builds/server/Reia']