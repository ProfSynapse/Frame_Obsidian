-- frame_data_collector.lua

-- Capture image function
local function capture_image()
    frame.camera.auto(true, 'center_weighted')
    frame.sleep(1) -- Wait for exposure to stabilize
    frame.camera.capture{zoom=2, pan=0, quality=0.7} -- Adjust these parameters as needed
    local image_data = ""
    while true do
        local chunk = frame.camera.read(240) -- Read 240 bytes at a time
        if chunk == nil then break end
        image_data = image_data .. chunk
    end
    return image_data
end

-- Record audio function
local function record_audio(duration)
    frame.microphone.start{sample_rate=16000, bit_depth=8}
    local audio_data = ""
    local start_time = frame.time.utc()
    while frame.time.utc() - start_time < duration do
        local chunk = frame.microphone.read(240) -- Read 240 bytes at a time
        if chunk ~= "" then
            audio_data = audio_data .. chunk
        end
    end
    frame.microphone.stop()
    return audio_data
end

-- Get IMU data function
local function get_imu_data()
    return frame.imu.direction()
end

-- Function to encode data as base64
local function encode_base64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- Main data collection and sending function
local function collect_and_send_data()
    local image = capture_image()
    local audio = record_audio(5) -- 5 seconds of audio
    local imu = get_imu_data()
    
    -- Prepare data for sending
    local data = {
        type = "obsidian_sync",
        payload = {
            image = encode_base64(image),
            audio = encode_base64(audio),
            imu = imu,
            timestamp = frame.time.utc()
        }
    }
    
    -- Convert data to JSON string
    local json_data = frame.json.encode(data)
    
    -- Send data over Bluetooth
    local chunks = {}
    for i = 1, #json_data, 240 do
        chunks[#chunks + 1] = json_data:sub(i, i + 239)
    end
    
    for _, chunk in ipairs(chunks) do
        frame.bluetooth.send(chunk)
        frame.sleep(0.05) -- Small delay to prevent overwhelming the receiver
    end
end

-- Set up tap callback to trigger data collection
frame.imu.tap_callback(collect_and_send_data)

-- Main loop
while true do
    frame.sleep() -- Sleep until woken by a tap
end