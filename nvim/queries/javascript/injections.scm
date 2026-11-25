;; extends

; three.js shaders: /* glsl */ `...`
((comment) @_c
  (#lua-match? @_c "^/%*%s*glsl%s*%*/$")
  .
  (template_string) @injection.content
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "glsl"))

; glsl`...` (vite-plugin-glsl, glslify)
(call_expression
  function: (identifier) @_name
  (#eq? @_name "glsl")
  arguments: (template_string) @injection.content
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "glsl"))
