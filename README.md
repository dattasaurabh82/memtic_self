# memtic_self

* [PROJECT PAGE](https://www.dattasaurabh.com/mi-e-metic-self)
* [INSTALLATION GUIDE](https://dattabaumstudio.notion.site/Mimetic-self-Installation-and-Maintenance-Guide-89d1f03d15b848089516b9a0ae4b9f4f?pvs=4)

## System Architecture overview:
```mermaid
sequenceDiagram
    autonumber
    participant Processing_GUI
    participant python_AI_API_req_maker
    participant img_data.json
    participant python_gif_req_maker
    participant gif_data.json
    participant PI_python_OMX_player
    participant HW_swiper

    Note over Processing_GUI: mount network loaction of PI
    loop Every few minutes (configurable in app)
        Processing_GUI->>PI_python_OMX_player:  MQTT: stop omx player

        Note over Processing_GUI: capture image
        
        alt got captions and bounding box
            Processing_GUI->>python_AI_API_req_maker: CMD: raw.png + img_data.json

            activate Processing_GUI

            python_AI_API_req_maker-->>img_data.json: FILE_IO: formatted json response
            
            img_data.json-->>Processing_GUI: FILE_IO:parse a random caption and bounding boxes
            
            Processing_GUI->>python_gif_req_maker: CMD: caption + gif_data.json

            activate python_gif_req_maker

            python_gif_req_maker-->>gif_data.json: FILE_IO: formatted json response

            gif_data.json-->>Processing_GUI: FILE_IO: parse gif url

            deactivate python_gif_req_maker

            Note over Processing_GUI: download gif in network location

            Processing_GUI->>PI_python_OMX_player: CURL: MQTT: start omx player 

            deactivate Processing_GUI

            Note over PI_python_OMX_player: loop new GIF
        
        else caption req error
            Processing_GUI-xpython_AI_API_req_maker: CMD: raw.png + img_data.json

            activate Processing_GUI
            
            python_AI_API_req_maker-ximg_data.json: FILE_IO: exception for json response
            
            Processing_GUI->>PI_python_OMX_player: CURL: show error gif + MQTT: start omx player 

            deactivate Processing_GUI

            Note over PI_python_OMX_player: loop error fixed GIF
        else gif req error
            Processing_GUI->>python_AI_API_req_maker: CMD: raw.png + img_data.json

            activate Processing_GUI
            
            python_AI_API_req_maker->>img_data.json: FILE_IO: exception for json response

            img_data.json-->>Processing_GUI: FILE_IO:parse a random caption and bounding boxes
            
            Processing_GUI-xpython_gif_req_maker: CMD: caption + gif_data.json

            python_gif_req_maker--xgif_data.json: FILE_IO: exception for json response

            Processing_GUI->>PI_python_OMX_player: CURL: show error gif + MQTT: start omx player 

            deactivate Processing_GUI

            Note over PI_python_OMX_player: loop error fixed GIF
        end

        Note over Processing_GUI,HW_swiper: In any case, it send a swipe signal and awaits for swipe finish

        Processing_GUI->>HW_swiper: SERIAL: scroll tiktok
        activate Processing_GUI
       
        Note over HW_swiper: Swipe
        
        activate HW_swiper
        
        HW_swiper->>Processing_GUI: done swipping
        deactivate HW_swiper
        deactivate Processing_GUI
    end
    
```
