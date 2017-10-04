#!/usr/bin/env python

#from __future__ import print_function

import os
import numpy as np
from flask import Flask, jsonify, render_template, request
import json
from grpc.beta import implementations
import tensorflow as tf
from tensorflow_serving.apis import predict_pb2
from tensorflow_serving.apis import prediction_service_pb2
from tensorflow.core.framework import types_pb2
from google.protobuf.json_format import MessageToJson
from grpc.framework.interfaces.face.face import AbortionError


app = Flask(__name__)


@app.route('/recognize', methods=['POST'])
def recognize():
    host = os.environ.get('PREDICTION_HOST1', '0.0.0.0')
    port = os.environ.get('PREDICTION_PORT1', '6006')
    print "...."
    try:
        channel = implementations.insecure_channel(host, int(port))
        stub = prediction_service_pb2.beta_create_PredictionService_stub(channel)
          # Send request
        f = request.files['image']
        data = f.read()
        tfrequest = predict_pb2.PredictRequest()
        tfrequest.model_spec.name = 'inception'
        tfrequest.model_spec.signature_name = 'predict_images'
        tfrequest.inputs['images'].CopyFrom(tf.contrib.util.make_tensor_proto(data, shape=[1]))
        result = stub.Predict(tfrequest, 10.0)  # 10 secs timeout
        print(result)
        jsonresult = MessageToJson(result)
        finalresult = json.loads(jsonresult)
        classes = finalresult["outputs"]["classes"]['stringVal']
        scores = finalresult["outputs"]["scores"]["floatVal"]
        results=[]
        for x, y in zip(classes,scores):
            results.append({'label': x.decode('base64'), 'score': y})
        return render_template('result.html', results=results)
    except:
        results=[]
        results.append({'label': 'error', 'score': '500'})
        return render_template('result.html', results=results)
    


@app.route('/')
def root():
    return render_template('index.html')


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)
