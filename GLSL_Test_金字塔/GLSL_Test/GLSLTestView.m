//
//  GLSLTestView.m
//  GLSL_Test
//
//  Created by leosun on 2020/7/30.
//  Copyright © 2020 leosun. All rights reserved.
//

/*
不采样GLKBaseEffect，使用编译链接自定义的着色器（shader）。用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换。
思路：
  1.创建图层
  2.创建上下文
  3.清空缓存区
  4.设置RenderBuffer
  5.设置FrameBuffer
  6.开始绘制
*/

#import <OpenGLES/ES3/gl.h>
#import "GLSLTestView.h"
#import "GLESMath.h"

@interface GLSLTestView ()

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承自CALyayer
@property(nonatomic,strong)CAEAGLLayer *myLayer;
@property(nonatomic,strong)EAGLContext *context;

@property(nonatomic,assign)GLuint myFrameBuffer;
@property(nonatomic,assign)GLuint myRenderBuffer;

@property(nonatomic,assign)GLuint myProgram;

@property(nonatomic,assign)GLuint myVertices;

@end

@implementation GLSLTestView
{
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
    
}

-(void)layoutSubviews{
    [super layoutSubviews];
    //1 设置图层
    [self setupLayer];
    //2 设置上下文
    [self setupContext];
    //3.清空缓存区
    [self deleteRenderAndFrameBuffer];
    //4.设置RenderBuffer
    [self setupRenderBuffer];
    //5.设置setupFrameBuffer
    [self setupFrameBuffer];
    //6.开始绘制
    [self renderLayer];
}

//没有该方法，layer不会赋值给CAEAGLLayer
+(Class)layerClass{
    return [CAEAGLLayer class];
}

// 1.设置图层
-(void)setupLayer{
    //1.创建特殊图层
    /*
     重写layerClass，将CCView返回的图层从CALayer替换成CAEAGLLayer
     */
    self.myLayer = (CAEAGLLayer *)self.layer;
    NSLog(@"%@",self.myLayer);
    
    //设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    //3.设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
     kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
     kEAGLDrawablePropertyColorFormat
         可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     
         kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
         kEAGLColorFormatRGB565：16位RGB的颜色，
         kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。


     */
//    self.myLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
    self.myLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@false,kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
}

// 2.设置上下文
-(void)setupContext{
    //设置上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES3)];
    //判断是否创建成功
    if (!context) {
        NSLog(@"创建失败");
        return;
    }
    //设置当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"设置当前上下文失败");
        return;
    }
    //把上下文设置全局
    self.context = context;
}

// 3.清空缓冲区
-(void)deleteRenderAndFrameBuffer{
    /*
    buffer分为frame buffer 和 render buffer2个大类。
    其中frame buffer 相当于render buffer的管理者。
    frame buffer object即称FBO。
    render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
    */
    glDeleteRenderbuffers(1, &(_myRenderBuffer));
    self.myRenderBuffer = 0;
    
    glDeleteFramebuffers(1, &_myFrameBuffer);
    self.myFrameBuffer = 0;
}

//设置RenderBuffer
-(void)setupRenderBuffer{
    GLuint renderBuffer;
    //申请一个缓冲区标志
    glGenRenderbuffers(1, &renderBuffer);
    //绑定标识符到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    //将可绘制对象drawable object's  CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myLayer];
    self.myRenderBuffer = renderBuffer;
}

//设置FrameBuffer
-(void)setupFrameBuffer{
    GLuint frameBuffer;
    //申请一个缓冲区标志
    glGenFramebuffers(1, &frameBuffer);
    //绑定标识符到GL_RENDERBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    /*生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
     调用glFramebufferRenderbuffer函数进行绑定到对应的附着点上，后面的绘制才能起作用
     */
    self.myFrameBuffer = frameBuffer;
    
    //5.将渲染缓存区myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myRenderBuffer);
}

//开始绘制
-(void)renderLayer{
    //清理屏幕颜色
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    //14.开启剔除操作效果
//    glEnable(GL_DEPTH_TEST);
    
    //设置视口
    CGFloat scale = [[UIScreen mainScreen] scale];
    //2.设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    //获取顶点着色器和片元着色器位置
    NSString* vertextFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString* fragmentFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    //清除program缓存
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    //加载程序
    self.myProgram = [self loadVertexShader:vertextFile andFragShader:fragmentFile];
    glLinkProgram(self.myProgram);
    GLint linkStatus;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString *errorMsg = [NSString stringWithUTF8String:message];
        NSLog(@"%@",errorMsg);
        return;
    }
    
    //使用程序
    glUseProgram(self.myProgram);
    
    //8.创建顶点数组 & 索引数组
    //(1)顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,        0.0,0.0,                       //左上0
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,         1.0,0.0 ,                     //右上1
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,        0.0,1.0,                     //左下2
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,         1.0,1.0    ,                   //右下3
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,      0.5,0.5,                        //顶点4
    };
    
    //(2).索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //判断顶点数据是否为空，如果为空则创建
    if (self.myVertices == 0) {
        glGenBuffers(1, &(_myVertices));
    }
    //绑定顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //把顶点数据拷贝到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //(3).将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
    //3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    //打开通道
    glEnableVertexAttribArray(position);
    //设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (GLfloat *)NULL);
    
    //10.--------处理顶点颜色值-------
    //(1).glGetAttribLocation,用来获取vertex attribute的入口的.
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint postionColor = glGetAttribLocation(self.myProgram, "postionColor");
    //打开通道
    glEnableVertexAttribArray(postionColor);
    //设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(postionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (float *)NULL + 3);
    
    //纹理
    GLuint textcoordColor =  glGetAttribLocation(self.myProgram, "textCoordinate");
    glEnableVertexAttribArray(textcoordColor);
    glVertexAttribPointer(textcoordColor, 2, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (float *)NULL + 6);

    //加载纹理
    [self loadTexture:@"jay"];
    
    //设置纹理采样
    glUniform1i(glGetUniformLocation(self.myProgram, "textCoordMap"), 0);
    
    glUniform1f(glGetUniformLocation(self.myProgram, "alpha"), 0.1);
    
    //获取projectionMatrix和modelviewMatrix
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelviewMatrixSlot = glGetUniformLocation(self.myProgram, "modelviewMatrix");
    
    //创建投影矩阵
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    KSMatrix4 _projectionMatrix;
    //加载单元矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
    //获取纵横比
    float aspect = width/height;
    ksPerspective(&_projectionMatrix, 30, aspect, 5.0f, 20.0f);
    //(4)将投影矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    //13.创建一个4 * 4 矩阵，模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    //(1)获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    //(2)平移，z轴平移-10
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -6.0);
    //(3)创建一个4 * 4 矩阵，旋转矩阵
    KSMatrix4 _rotationMatrix;
    //(4)初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);
    //(5)旋转
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //绕Y轴
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0); //绕Z轴
    //(6)把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
     ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    //(7)将模型视图矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(modelviewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    //14.开启剔除操作效果
    glEnable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    //15.使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
                GL_POINTS
                GL_LINES
                GL_LINE_LOOP
                GL_LINE_STRIP
                GL_TRIANGLES
                GL_TRIANGLE_STRIP
                GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
             GL_BYTE
             GL_UNSIGNED_BYTE
             GL_SHORT
             GL_UNSIGNED_SHORT
             GL_INT
             GL_UNSIGNED_INT
     indices：绘制索引数组

     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma -mark loadShader
-(GLuint)loadVertexShader:(NSString *)vertext andFragShader:(NSString *)fragment{
    GLuint vShader,fShader;
    //创建program
    GLint program = glCreateProgram();
    
    //2.编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&vShader withType:GL_VERTEX_SHADER andPath:vertext];
    [self compileShader:&fShader withType:GL_FRAGMENT_SHADER andPath:fragment];
    
    //把编译好的程序附着到shader（shader -> program）
    glAttachShader(program, vShader);
    glAttachShader(program, fShader);
    
    //删除shader  以免占用内存
    glDeleteShader(vShader);
    glDeleteShader(fShader);

    return program;
}

#pragma -mark compileShader
-(void)compileShader:(GLuint *)shader withType:(GLenum)type andPath:(NSString *)path{
    //1.读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //转化成c语言字符串
    const GLchar *source = [content UTF8String];
    
    //2.创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //3.将着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, nil);
    
    //把着色器代码编译成目标代码
    glCompileShader(*shader);
}

-(void)loadTexture:(NSString *)textureName{
    CGImageRef image = [UIImage imageNamed:textureName].CGImage;
    if (image == nil) {
        NSLog(@"读取图片失败");
        exit(1);
    }
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    //获取图片字节数
    GLubyte *data = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    //创建上下文
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width * 4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
    //使用默认方式绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    //释放
    CGContextRelease(context);
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //9.设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLfloat)width, (GLfloat)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    //释放data
    free(data);

}


- (IBAction)xClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bX = !bX;
}

- (IBAction)yClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bY = !bY;
}

- (IBAction)zClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bZ = !bZ;
}

-(void)reDegree
{
    //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
    //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    //重新渲染
    [self renderLayer];
    
}

@end
