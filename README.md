# install

    $ pip install -r requirements.txt
    $ python main.py 

# dockerbuild

docker build -t submod/inception-app -f Dockerfile .

# deployment

1. Ensure that you are connected to an OpenShift project
```
oc new-project test
```
2. Create the template for inception web application.
```
oc create -f https://raw.githubusercontent.com/sub-mod/inception-app/master/template.json
```
3. Create the template for tensorflow serving endpoints.
```
oc create -f https://raw.githubusercontent.com/sub-mod/mnist-models/master/template.json
```
4. Launch tensorflow serving s2i build for the tensorflow models.We need to create a prediction 
   endpoints with inception model.
```
oc new-app --template=tensorflow-server --param=APPLICATION_NAME=tf-inception \
	--param=MODEL_IMAGE=submod/inception-model \
	--param=IMAGE_MODEL_PATH=/models/inception/1/  \
	--param=MODEL_NAME=inception \
	--param=MODEL_PATH=1
```
5. Launch the inception web application.
```
oc new-app --template=inceptionapp --param=APPLICATION_NAME=inception-app --param=PREDICTION_SERVICE1=tf-inception 
```
