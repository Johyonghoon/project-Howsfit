#  python -m uvicorn main:app --reload --port 8000

import cv2
import os
import json
import pose
import base64
import requests
import subprocess
from PIL import Image
from io import BytesIO
from starlette.responses import HTMLResponse
from fastapi import FastAPI, File, UploadFile

from agnostics.get_img_agnostic import getting_img_agnostic
from agnostics.get_parse_agnostic import get_parse_agnostic
from utils.time import current_time
from cloth_mask import get_cloth_mask
from humanparse.get_human_parse import get_human_parse
from img_paste import merge

from fastapi.middleware.cors import CORSMiddleware

origins = ["http://127.0.0.1:3000",
           'http://localhost:3000',
           'https://johyonghoon.shop',
           'http://johyonghoon.shop',
           ]

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def home():
    return HTMLResponse(content=f"""
    <body>
    <div>
        <h1 style="width:400px;margin:50px auto">
            {current_time()} <br/>
            현재 서버 구동 중 입니다. 
         </h1>
    </div>
    </body>
        """)


@app.get("/image-resize")
async def async_image_resize():

    print(" >>>>> Image Resize ! ")
    image = cv2.imread("data/test/image/test_1.jpg")
    width = 768
    height = 1024
    dim = (width, height)
    resized_image = cv2.resize(image, dim)
    cv2.imwrite("data/test/image/test_1.jpg", resized_image)


@app.post("/cloth-preprocess")
async def cloth_preprocess(image: UploadFile = File(...)):

    print(" >>>>> Start Cloth Preprocess !")
    cloth_path = "data/test/cloth"
    cloth_fname = 'test_1.jpg'
    cloth_location = os.path.join(cloth_path, cloth_fname)
    with open(cloth_location, "wb") as buffer:
        buffer.write(await image.read())
    img = cv2.imread(cloth_location)
    resized_img = cv2.resize(img, (768, 1024))
    cv2.imwrite(cloth_location, resized_img)

    get_cloth_mask(cloth_fname)

    with open(f"data/test/cloth-mask/{cloth_fname}", "rb") as img_file:
        image_bytes = img_file.read()

    output = base64.b64encode(image_bytes).decode()
    print(" >>>>> Success Cloth Preprocess !")
    return {"data": output}


@app.post("/human-parse")
async def async_human_parse(img_name):
    print(" >>>>> Start Preprocess :: Human Parse")
    print(" >>>>> Request Human Parse to 8010 port server")
    image_path = f"data/test/image/{img_name}"
    humanparse_url = "http://127.0.0.1:8010/parse"
    with open(image_path, "rb") as f:
        files = {"file": (img_name, f)}
        name, ext = img_name.split('.')
        result = requests.post(humanparse_url, files=files)
        if result.status_code == 200:
            response = json.loads(result.content)
            img_parse_maps = Image.open(BytesIO(base64.b64decode(response[0])))
            img_parse_color = Image.open(BytesIO(base64.b64decode(response[1])))
            parse_path = "data/test/image-parse-v3"
            parse_maps = os.path.join(parse_path, f"{name}.png")
            parse_color = os.path.join(parse_path, f"{name}_color.png")
            img_parse_maps.save(parse_maps)
            img_parse_color.save(parse_color)
            print(" >>>>> Return Human Parse Image successfully")
            print(" >>>>> Success Human Parse ! ")
        else:
            print("Error occurred during image transfer")


@app.get("/densepose")
async def async_densepose():
    print(" >>>>> Start Preprocess :: Densepose")
    terminnal_command = "python DensePose/apply_net.py " \
                        "show DensePose/configs/densepose_rcnn_R_50_FPN_s1x.yaml " \
                        "DensePose/model_densepose.pkl data/test/image " \
                        "dp_segm -v --opts MODEL.DEVICE cpu"
    os.system(terminnal_command)
    print(" >>>>> Success Densepose ! ")


@app.get("/openpose")
async def async_openpose():
    print(" >>>>> Start Preprocess :: Openpose")
    os.chdir("./openpose")
    subprocess.call('artifacts/bin/OpenPoseDemo.exe '
                    '--image_dir ../data/test/image '
                    '--write_json ../data/test/openpose_json '
                    '--write_images ../data/test/openpose_img '
                    '--display 0'
                    )
    os.chdir("../")
    print(" >>>>> Success Openpose ! ")


@app.get("/agnostic")
async def async_agnostic():
    print(" >>>>> Start Preprocess :: Agnostics")
    os.chdir("./agnostics")
    getting_img_agnostic("test_1.jpg")
    get_parse_agnostic("test_1.jpg")
    os.chdir("../")
    print(" >>>>> Success Agnostics ! ")


@app.post("/model-preprocess-local")
async def model_preprocess_local(image: UploadFile = File(...)):
    print(" >>>>> Start Model Preprocess !")
    model_path = "data/test/image"
    model_fname = "test_1.jpg"
    name, ext = model_fname.split('.')
    model_location = os.path.join(model_path, model_fname)
    with open(model_location, "wb") as buffer:
        buffer.write(await image.read())

    # model preprocess 0 :: image-resize
    await async_image_resize()

    # model preprocess 1 :: human-parse
    await async_human_parse(model_fname)

    # model preprocess 2 :: Densepose
    await async_densepose()

    # model preprocess 3 :: Openpose
    await async_openpose()

    # model preprocess 4 :: Agnostic
    await async_agnostic()

    merge(f'./data/test/image-densepose/{model_fname}',
          f'./data/test/openpose_img/{name}_rendered.png',
          f'./data/test/image-parse-v3/{name}_color.png',
          f'./data/test/agnostic-v3.2/{name}.jpg'
          )
    print(" >>>>> Success All Preprocess ! ")

    with open(f"./data/merged_img/merged_image.jpg", "rb") as img_file:
        image_bytes = img_file.read()
    output = base64.b64encode(image_bytes).decode()

    print(" >>>>> Success return preprocess image to Web Page !")

    return {"data": output}


@app.post("/model-preprocess-aws-cpu")
async def model_preprocess_cpu(image: UploadFile = File(...)):
    model_path = "data/test/image"
    model_fname = "test_1.jpg"
    file_location = os.path.join(model_path, model_fname)
    with open(file_location, "wb") as buffer:
        buffer.write(await image.read())
    img = cv2.imread(file_location)
    resized_img = cv2.resize(img, (768, 1024))
    cv2.imwrite(file_location, resized_img)

    os.chdir("./humanparse")
    get_human_parse(model_fname)
    os.chdir("../")
    print('finish')

    pose.get_posenet(file_location)

    terminnal_command = "python DensePose/apply_net.py " \
                        "show DensePose/configs/densepose_rcnn_R_50_FPN_s1x.yaml " \
                        "DensePose/model_densepose.pkl " \
                        r"data/test/image dp_segm -v --opts MODEL.DEVICE cpu"
    os.system(terminnal_command)

    os.chdir("./agnostics")
    getting_img_agnostic(model_fname)
    get_parse_agnostic(model_fname)
    os.chdir("../")

    #remove_back(file_location)

    merge('./data/test/image-densepose/test_1.jpg',
          './data/test/openpose_img/test_1_rendered.png',
          './data/test/image-parse-v3/test_1_color.png',
          './data/test/agnostic-v3.2/test_1.jpg')

    with open(f"./data/merged_img/merged_image.jpg", "rb") as img_file:
        print(img_file)
        image_bytes = img_file.read()

    output = base64.b64encode(image_bytes).decode()
    return {"data": output}


@app.post("/try-on")
async def try_on():
    print(" >>>>> Start Virtual Try On !")
    weight_path = "try_on/eval_models/weights/v0.1"
    terminnal_command = f"python try_on/my_test_generator.py " \
                        f"--test_name viton " \
                        f"--tocg_checkpoint {weight_path}/tocg_final.pth " \
                        f"--gpu_ids 0 " \
                        f"--gen_checkpoint {weight_path}/gen_model_final.pth " \
                        f"--datasetting unpaired " \
                        f"--data_list test_pairs.txt " \
                        f"--dataroot ./data"
    os.system(terminnal_command)

    print(" >>>>> Success Virtual Try On ! ")

    fname = 'test_1_test_1.png'
    with open(f"output/viton/{fname}", "rb") as img_file:
        image_bytes = img_file.read()

    output = base64.b64encode(image_bytes).decode()

    print(" >>>>> Success return VITON image to Web Page !")
    return {"data": output}
