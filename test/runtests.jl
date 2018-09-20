function is_ci()
    get(ENV, "TRAVIS", "") == "true" ||
    get(ENV, "APPVEYOR", "") == "true" ||
    get(ENV, "CI", "") == "true"
end

using GLAbstraction, GeometryTypes, ModernGL, FileIO, GLWindow
using ColorTypes
using Base.Test
import GLAbstraction: N0f8
import Reactive: Signal



include("macro_test.jl")

if !is_ci() # only do test if not CI... this is for automated testing environments which fail for OpenGL stuff, but I'd like to test if at least including works

window = create_glcontext("test", resolution=(500,500))

include("accessors.jl")
include("uniforms.jl")
include("texture.jl")
include("macro_test.jl")

# Test for creating a GLBuffer with a 1D Julia Array
# You need to supply the cardinality, as it can't be inferred
# indexbuffer is a shortcut for GLBuffer(GLUInt[0,1,2,2,3,0], 1, buffertype = GL_ELEMENT_ARRAY_BUFFER)
indexes = indexbuffer(GLuint[0,1,2])
# Test for creating a GLBuffer with a 1D Julia Array of Vectors
#v = Vec2f[Vec2f(0.0, 0.5), Vec2f(0.5, -0.5), Vec2f(-0.5,-0.5)]

v = Vec2f0[Vec2f0(0.0, 0.5), Vec2f0(0.5, -0.5), Vec2f0(-0.5,-0.5)]

verts = GLBuffer(v)
@test size(verts, 1) == 3
@test size(verts, 2) == 1

# lets define some uniforms
# uniforms are shader variables, which are supposed to stay the same for an entire draw call
cd(dirname(@__FILE__))
const triangle = std_renderobject(
    Dict(
        :vertex => verts,
        :name_doesnt_matter_for_indexes => indexes
    ),
    LazyShader("test.vert", "test.frag")
)

glClearColor(0,0,0,1)
i = 1
while isopen(window) && i < 20
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    GLAbstraction.render(triangle)
    swapbuffers(window)
    poll_glfw()
    sleep(0.01)
    i += 1
end
GLFW.DestroyWindow(window)

# test for type stability in translate_cam
translate = Vec3f0([1.0, 1.0, 1.0])
proj = Signal(Mat4{Float32}(eye(Float32,4)))
view_test = Signal(Mat4{Float32}(eye(Float32,4)))
window_size = Signal(SimpleRectangle(-1, -1, 1, 1)) #from DummyCamera
prj_type = Signal(PERSPECTIVE)
eyepos_s = Signal(Vec3f0([1.0, 0.0, 0.0]))
lookat_s = Signal(Vec3f0([0.0, 1.0, 0.0]))
up_s = Signal(Vec3f0([0.0, 0.0, 1.0]))
# Record original types
type_eyepos = typeof(eyepos_s)
type_lookat = typeof(lookat_s)

GLAbstraction.translate_cam(
    translate,
    proj,
    view_test,
    window_size,
    prj_type,
    eyepos_s,
    lookat_s,
    up_s
)

@test typeof(eyepos_s)==type_eyepos
@test typeof(lookat_s)==type_lookat

end
