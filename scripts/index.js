// Code to read, load, compile, link, run and render
// (to an HTML5 canvas) a vertex and a fragment shader 

document.onreadystatechange = () => {
    if (document.readyState === 'complete') {
       
        // Get reference to canvas, set dimensions
        const canvas = document.getElementById(`canv0`);
        let canvasSize = Math.min(window.innerHeight, window.innerWidth) - 200;
        let [w, h] = [canvasSize, canvasSize];
        [canvas.width, canvas.height] = [w, h];
        let [mx, my] = [0.0, 0.0];  // Mouse position in canvas, normalised to range(-1, 1)

        // Link canvas to a WebGL context
        const gl = canvas.getContext(`webgl`) || canvas.getContext(`experimental-webgl`);

        // Initialise context
        gl.viewport(0, 0, w, h);
        gl.clearColor(0.0, 0, 0.0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // Create some points to send to the vertex shader and set up a buffer for passing them to the GPU
        const triangleVertices = [
            //   x        y        
                -1.0,    -1.0,
                 1.0,    -1.0,
                -1.0,     1.0,
                 1.0,    -1.0,
                 1.0,     1.0,
                -1.0,     1.0,
        ];
        let triangleVertexBufferObject = gl.createBuffer();

        let vShaderCode, fShaderCode;   // strings read from user-specified files
        let vertexShader, fragmentShader;

        // Get refs to the input elements that let user choose the files that contain the shader code
        let vs_input = document.getElementById('vs-code-input');
        let fs_input = document.getElementById('fs-code-input');

        let t0;             // t0 will store the initial time, just before first render
        let pause_time;     // pause_time will store the time the user paused rendering
        let time_location;  // time_location will refer to where the GPU stores u_time
        let resolution_location;    // resolution_location will refer to where GPU stores u_resolution
        let mouse_location; // mouse_location will refer to where GPU stores u_mouse
        
        // State booleans: Vertex shader loaded? / Fragment6 shader loaded? / User clicked "Pause"? 
        //                 Eucllidean or Manhattan distance metric? / Clock started?
        let [vs_loaded, fs_loaded, paused, euclidean, started] = [false, false, false, false, false];

        // Listen for user choosing the shader files
        for (let input of [vs_input, fs_input]) {
          input.addEventListener('change', handleFileSelect, false);  
        }

        // Listen for user clicking Pause / Run
        document.getElementById("sh-btn-pause").addEventListener('click', function() {
            paused = !paused;
            if (paused) {
                pause_time = Date.now();
            }
            else {
                t0 += Date.now() - pause_time;
            }
            this.textContent = paused ? "Run" : "Pause";  
            render(); 
        });

        // Listen for user clicking to change the distance metric
        document.getElementById("sh-btn-metric").addEventListener('click', function() {
            euclidean = !euclidean;
            this.textContent = euclidean ? "Manhattan" : "Euclidean";
            fShaderCode = euclidean ? fShaderCode.replace(`minkd(uv, p, 1.)`, `minkd(uv, p, 2.)`)
                                    : fShaderCode.replace(`minkd(uv, p, 2.)`, `minkd(uv, p, 1.)`);
            gl.shaderSource(fragmentShader, fShaderCode);
            gl.compileShader(fragmentShader);
            console.log(`Re-linking shaders...`)  
            linkShaders(); 
        });

        // Click on Reset button calls reset(), which zeroes the timer t0.
        document.getElementById("sh-btn-reset").addEventListener('click', reset);

        canvas.onmousemove = handleMouseMove;

        // Read & compile user-selected shader; if no compile errors, set state flag to show it's been loaded;
        // If the other shader's `loaded` flag is also set, then spring into action by initiating linking
        // which leads on to the shaders actually being run.
        function handleFileSelect(e0) {
            f = e0.target.files[0];
            let rdr = new FileReader();
            rdr.readAsText(f);
            // test when read
            rdr.onloadend = function(e1) {
                if (e1.target.readyState == FileReader.DONE) {
                    if (e0.target === vs_input) {
                        vShaderCode = rdr.result;
                        console.log(`*** Vertex shader source code *** \n\n${vShaderCode}\n\n`);
                        // Load and compile vertex shader code
                        vertexShader = gl.createShader(gl.VERTEX_SHADER);
                        gl.shaderSource(vertexShader, vShaderCode);
                        gl.compileShader(vertexShader);
                        if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
                            console.error(`*** ERROR compiling vertex shader ***`, gl.getShaderInfoLog(vertexShader));
                            return;
                        }
                        else {
                            vs_loaded = true;
                            // if both oil and petrol loaded, then start the engine!
                            if (fs_loaded) linkShaders();
                        }
                    }
                    else if (e0.target === fs_input) {
                        fShaderCode = rdr.result;
                        console.log(`*** Fragment shader source code *** \n\n${fShaderCode}\n\n`);
                        // Load and compile fragment shader code
                        fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
                        gl.shaderSource(fragmentShader, fShaderCode);
                        gl.compileShader(fragmentShader);
                        if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
                            console.error(`*** ERROR compiling fragment shader ***`, gl.getShaderInfoLog(fragmentShader));
                            return;
                        }
                        else {
                            fs_loaded = true;
                            // if both oil and petrol loaded, then start the engine!
                            if (vs_loaded) linkShaders();
                        }
                    }
                }
            }
        }

        // Called from handleFileSelect(); both shaders are now compiled & loaded,
        // so link them into a `program` 
        function linkShaders() {
            console.log(`*** INFO:  Linking shaders... ***`);
            let program = gl.createProgram();
            gl.attachShader(program, vertexShader);
            gl.attachShader(program, fragmentShader);
            gl.linkProgram(program);
            if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
                console.error(`*** ERROR linking program ***`, gl.getProgramInfoLog(program));
                return;
            }
            console.log(`*** INFO:  Validating program... ***`);
            gl.validateProgram(program);
            if (!gl.getProgramParameter(program, gl.VALIDATE_STATUS)) {
                console.error(`*** ERROR validating program ***`, gl.getProgramInfoLog(program));
                return;
            }
            setupBuffers();
            linkAttributes(program);
            gl.useProgram(program);

            time_location = gl.getUniformLocation(program, `u_time`);
            resolution_location = gl.getUniformLocation(program, `u_resolution`);
            mouse_location = gl.getUniformLocation(program, `u_mouse`); 
            if (!started) {
                t0 = Date.now();
            }
            started = true;
            render(program);  
        }

        function setupBuffers() {
            gl.bindBuffer(gl.ARRAY_BUFFER, triangleVertexBufferObject);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(triangleVertices), gl.STATIC_DRAW);
        }

        function linkAttributes(program) {
            let positionAttribLocation = gl.getAttribLocation(program, `vertPosition`);
            let colourAttribLocation = gl.getAttribLocation(program, `vertColour`);
            gl.vertexAttribPointer(
                positionAttribLocation,  // Attribute location
                2,                                         // Number of elements per attribute
                gl.FLOAT,                                  // Type of elements
                gl.FALSE,                                  // Whether data is normalised
                2 * Float32Array.BYTES_PER_ELEMENT,        // Size of an individual vertex
                0,                                         // Offset from beginning of a single vertex to this attribute
            );

            gl.enableVertexAttribArray(positionAttribLocation);
        }

        function render(program) {
            if (!paused) {
                let u_time = 0.001 * (Date.now() - t0);
                gl.uniform1f(time_location, u_time);
                gl.uniform2f (resolution_location, w, h);
                gl.uniform2f(mouse_location, mx, my);              
                gl.drawArrays(
                    gl.TRIANGLES,   // WebGL drawing mode
                    0,              // How many vertices to skip
                    6,              // How many vertices to draw
                );
                requestAnimationFrame(render);
            }
        }

        function handleMouseMove(ev) {
            let bounds = canvas.getBoundingClientRect();
            [mx, my] = [2.0 * (ev.clientX - bounds.left) / bounds.width - 1.0,
                        2.0 * (ev.clientY - bounds.top) / bounds.height - 1.0];            
        }

        function reset() {
            t0 = Date.now();
        }
    }
};