package
{
	import away3dlite.animators.BonesAnimator;
	import away3dlite.containers.ObjectContainer3D;
	import away3dlite.core.base.Object3D;
	import away3dlite.core.utils.Debug;
	import away3dlite.events.Loader3DEvent;
	import away3dlite.loaders.Collada;
	import away3dlite.loaders.Loader3D;
	import away3dlite.materials.WireColorMaterial;
	import away3dlite.primitives.Sphere;
	import away3dlite.templates.BasicTemplate;
	
	import com.greensock.TweenLite;
	import com.logosware.event.QRdecoderEvent;
	import com.logosware.event.QRreaderEvent;
	import com.logosware.utils.QRcode.GetQRimage;
	import com.logosware.utils.QRcode.QRdecode;
	import com.sleepydesign.utils.FileUtil;
	import com.sleepydesign.utils.LoaderUtil;
	import com.sleepydesign.utils.ObjectUtil;
	import com.sleepydesign.utils.SystemUtil;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.URLVariables;
	import flash.utils.*;
	
	import org.libspark.flartoolkit.core.FLARCode;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.detector.FLARMultiMarkerDetector;
	import org.libspark.flartoolkit.support.sandy.FLARBaseNode;
	import org.libspark.flartoolkit.support.sandy.FLARCamera3D;
	
	import sandy.core.Scene3D;
	import sandy.core.data.Point3D;
	import sandy.core.data.Polygon;
	import sandy.core.scenegraph.Group;
	import sandy.materials.attributes.LineAttributes;
	import sandy.primitive.Plane3D;

	
	/**
	 * QRCodeReader + FLARToolKit PoC (libspark rev. 3199, sandy rev. 1138)
	 * @license GPLv2
	 * @author makc
	 * 
	 * @see http://www.openqrcode.com/
	 * 
	 * [Step #1]
	 * 1.1 Loading Effect
	 * 1.2 Server 	--> Session[UserID] --> Flash
	 * 1.3 User 	--> Image[QR, AR] 	--> Model ID, Projection Matrix
	 * 1.4 Wait for User playing/proceed to next step
	 * 
	 * [Step #2]
	 * 2.1 Loading Effect
	 * 2.2 Flash 	--> Encypt[Time, UserID, ModelID]	--> Server
	 * 2.3 Flash 	<-- Model[Mesh, Texture, Animation]	<-- Server
	 * 2.4 Spawn Effect
	 * 
	 * [Step #3]
	 * 3.1 Wait for user input for next step
	 * 3.2 Flip Effect to next ingradient
	 * 3.3 Repeat step 1.2 --> 3.2 until finish condition?
	 * 
	 * [Step #4]
	 * 4.1 Loading Effect
	 * 4.2 Flash 	--> Encypt[Time, UserID, ModelID, ModelID]	--> Server
	 * 4.3 Flash 	<-- Model[Mesh, Texture, Animation]			<-- Server
	 * 4.4 Spawn Effect
	 * 
	 */
	[SWF(backgroundColor="0x333333", frameRate="30", width="800", height="240")]
	public class main extends BasicTemplate
	{
		private var base:Sprite;
		
		private var cameraContainer:Sprite;
		private var container:Sprite;
		
		private var paper:Sprite;
		private var tool:Sprite;
		
		private var _bitmap:Bitmap;
		
		private var A:FLARResult; 
		private var B:FLARResult; 
		private var C:FLARResult; 
		
		private var _A:FLARResult; 
		private var _B:FLARResult; 
		private var _C:FLARResult; 
		
		protected var _webcam:Camera;
		protected var _video:Video;
		private var _width:int=320;
		private var _height:int=240;
		
		private var _capture:Bitmap;
		private var isCam:Boolean = false;
		
		// Collada
		private var collada:Collada;
		private var loader:Loader3D;
		private var model:Object3D;
		private var skinAnimation:BonesAnimator;
		private var modelRoot:ObjectContainer3D;
		
		private function onSuccess(event:Loader3DEvent):void
		{
			model = loader.handle;
			model.rotationX = -90;
			skinAnimation = model.animationLibrary.getAnimation("default").animation as BonesAnimator;
		}
		
		private function initCollada():void
		{
			modelRoot = new ObjectContainer3D();
			scene.addChild(modelRoot);
			
			//Debug.active = true;
			
			collada = new Collada();
			collada.scaling = 25;
			
			loader = new Loader3D();
			loader.loadGeometry("assets/J7.dae", collada);
			loader.addEventListener(Loader3DEvent.LOAD_SUCCESS, onSuccess);
			modelRoot.addChild(loader);
		}
		
		override protected function onPreRender():void
		{
			getAxis();
			
			//setTransform(modelRoot, B);
			
			//modelRoot.lookAt( _sphereA.position );
			
			if(skinAnimation)
				skinAnimation.update(getTimer()/1000);
		}
		
		private var vX:Vector3D;
		private var vY:Vector3D;
		private var vZ:Vector3D;
		
		private var aa:Vector3D;
		private var bb:Vector3D;
		private var cc:Vector3D;
		private var dd:Vector3D;
		
		private var wtf:FLARResult;
		
		public function getAxis():void
		{
			if(aa && aa.x == _sphereA.position.x)return;
			
			aa = _sphereA.position.clone();
			bb = _sphereB.position.clone();
			cc = _sphereC.position.clone();
			
			//vZ = bb.subtract(aa);
			//vZ.normalize();
			if(wtf)
				setTransform(modelRoot, wtf.result);
			
			modelRoot.x = (aa.x + bb.x + cc.x)/3
			modelRoot.y = (aa.y + bb.y + cc.y)/3
			modelRoot.z = (aa.z + bb.z + cc.z)/3
			
			//modelRoot.lookAt( aa );
			//modelRoot.lookAt( bb );
			
/*
			vX = bb.subtract(cc);
			vX.normalize();

			// the real "up" vector is the dot product of X and Z
			vY = vX.crossProduct(vZ);
			
			//_sphereD.position = vY;
			
			//trace(vY);
			 
			vY.normalize();
*/		
			//trace("*"+vY);
		}
		
		public function main()
		{
			// sys
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			// layer
			base = new Sprite();
			addChild(base);
			
			container = new Sprite();
			addChild(container);
				
			cameraContainer = new Sprite();
			addChild(cameraContainer);
			//cameraContainer.visible = false;
			
			paper = new Sprite();
			container.addChild(paper);
			
			/*
			tool = new Sprite();
			addChild(tool);
			tool.visible = false;
			*/
		}
		
		private function initUser():void
		{
			// get user data
			LoaderUtil.loadVars("serverside/userData.php", onGetUserData);
		}
		
		private function onGetUserData(event:Event):void
		{
			// wait for complete
			if(event.type!="complete")return;
			
			var _userData:URLVariables = URLVariables(event.target["data"]);
			ObjectUtil.print(_userData);
		}
		
		private var _stuff:FLARBaseNode;
		private var _FLARCamera3D:FLARCamera3D;
		private function initARQR():void
		{
			// set up FLARToolKit
			canvas = new BitmapData(320, 240, false, 0);
			size = 100;
			param = new FLARParam;
			param.loadARParam(new CameraData);
			param.changeScreenSize(320, 240);
			code = new FLARCode(16, 16, 70, 70);
			code.loadARPatt(new MarkerData);
			raster = new FLARRgbRaster_BitmapData(canvas);
			detector = new FLARMultiMarkerDetector(param, [code], [size], 1);
			detector.setContinueMode(false);

			// set up sandy
			_FLARCamera3D = new FLARCamera3D(param, 0.001);
			sandyScene = new Scene3D("scene", Sprite(addChild(new Sprite)), _FLARCamera3D, new Group("root"));
			sandyScene.container.visible = false;
			stuff = new Vector.<FLARBaseNode>;
			for (var i:int = 0; i < 4; i++)
			{
				stuff[i] = new FLARBaseNode;
				var p:Plane3D = new Plane3D("plane" + i);
				LineAttributes(p.appearance.frontMaterial.attributes.attributes[0]).color = (i < 3) ? 0xFF00 : 0xFFFF00;
				p.rotateX = 180;
				stuff[i].addChild(p);
				sandyScene.root.addChild(stuff[i]);
			}
			
			_stuff = stuff[3];
			
			// set up lite
			camera.projection.fieldOfView = _FLARCamera3D.fov;
			camera.projection.focalLength = _FLARCamera3D.focalLength;

			// set up QRCodeReader
			homography = new BitmapData(240, 240, false, 0);
			var hbmp:Bitmap = new Bitmap(homography);
			hbmp.x = 320;
			base.addChild(hbmp);
			
			qrImage = new GetQRimage(hbmp);
			qrImage.addEventListener(QRreaderEvent.QR_IMAGE_READ_COMPLETE, onQRCodeRead);
			qrDecoder = new QRdecode();
			qrDecoder.addEventListener(QRdecoderEvent.QR_DECODE_COMPLETE, onQRDecoded);

			/*
			qrInfo = new TextField();
			qrInfo.filters = [new DropShadowFilter(0, 0, 0, 1, 3, 3, 10)];
			qrInfo.x = 320;
			qrInfo.textColor = 0xFF00;
			qrInfo.autoSize = "left";
			base.addChild(qrInfo);
			*/

			qrResult = homography.clone();
			var rbmp:Bitmap = new Bitmap(qrResult);
			rbmp.x = 560;
			base.addChild(rbmp);
			
			// add test image in the background
			setBitmap(Bitmap(new ImageData));
			
			// browse
			SystemUtil.addContext(this, "Open Image", function ():void{FileUtil.openImage(onImageReady)});
			SystemUtil.addContext(this, "Toggle Camera", onToggleSource);
			SystemUtil.addContext(this, "Reset Code", onResetCode);
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			
			//addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(Event.ENTER_FRAME, onRun);
		}
		
		//reset decode state
		private function onResetCode(event:ContextMenuEvent):void
		{
			isDecoded = false;
		}
		
		private function onToggleSource(event:ContextMenuEvent):void
		{
			isCam = !isCam;
			
			//trace("isCam : " + isCam);
			
			if(!isCam)
			{
				container.visible = true;
				cameraContainer.visible = false;
			}else{
				container.visible = false;
				cameraContainer.visible = true;
				
				if(!_webcam)
					_webcam = Camera.getCamera();
				
				if (_webcam) 
				{
					_webcam.setMode(_width, _height, 30);
					_video = new Video(_width, _height);
					_video.attachCamera(_webcam);
					_capture = new Bitmap(new BitmapData(_width, _height, false, 0), PixelSnapping.AUTO, true);
					cameraContainer.addChild(_capture);
				}
			}
			
			//dirty
			isDecoded = false;
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			TweenLite.to(paper, 1, {
				rotationX:30*Math.random()-30*Math.random(),
				rotationY:30*Math.random()-30*Math.random(),
				rotationZ:60*Math.random()-60*Math.random()
			});
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			//removeEventListener(Event.ENTER_FRAME, onRun);
		}
		
		private function onRun(event:Event):void
		{
			if(isCam && _capture && _video)
				_capture.bitmapData.draw(_video);
			
			sandyScene.render();
			
			process();
		}
		
		private function onImageReady(event:Event):void
		{
			if(event.type=="complete")
			{
				if(_bitmap)
					paper.removeChild(_bitmap);
				
				setBitmap(event.target.content);
			}
		}
		
		private function setBitmap(bitmap:Bitmap):void
		{
			isDecoded = false;
			
			_bitmap = bitmap;
			
			//3.2cm = 90px
			_bitmap.width = 90;
			_bitmap.height = 90;
			
			paper.x = 320/2-90/2;
			paper.y = 240/2-90/2;
			
			paper.addChild(_bitmap);
			
			// show time
			process();
		}

		private var aggregate:FLARTransMatResult
		
		private function process():void
		{
			//tool.graphics.clear();
			//tool.graphics.lineStyle();
						
			// get image into canvas
			//sandyScene.container.visible = false;
			canvas.fillRect(canvas.rect, 0);
			
			if(!isCam)
			{
				canvas.draw(container);
			}else{
				canvas.draw(cameraContainer);
			}
			
			//sandyScene.container.visible = true;

			// flarkit pass
			var n:int = detector.detectMarkerLite(raster, 128);
			if (n > 2)
			{
				// we want 3 best matches
				var k:int, results:Array = [];
				for (k = 0; k < n; k++)
				{
					var r:FLARResult = new FLARResult;
					r.confidence = detector.getConfidence(k);
					detector.getTransmationMatrix(k, r.result);
					r.square = detector.getResult(k).square;
					results.push(r);
				}

				results.sortOn("confidence", Array.DESCENDING | Array.NUMERIC);
				results.splice(3, n - 3);
				
				// sort them into right triangle
				//var A:FLARResult, B:FLARResult, C:FLARResult;
				for (k = 0; k < 3; k++)
				{
					A = FLARResult(results[(2 + k) % 3]);
					B = FLARResult(results[(3 + k) % 3]);
					C = FLARResult(results[(4 + k) % 3]);

					// I will use sandy math but not coordinates here (feel free to inline)
					var BA:Point3D = new Point3D((B.result.m03 - A.result.m03), (B.result.m13 - A.result.m13), (B.result.m23 - A.result.m23));
					var BC:Point3D = new Point3D((B.result.m03 - C.result.m03), (B.result.m13 - C.result.m13), (B.result.m23 - C.result.m23));
					// average distance is only meaningful for 1 vertex (you can compute it later)
					B.distance = 0.5 * (BA.getNorm() + BC.getNorm());
					BA.normalize();
					BC.normalize();
					B.cosine = Math.abs(BA.dot(BC));
				}

				results.sortOn("cosine", Array.NUMERIC);
				
				wtf = results[0];
				
				// display intermediate results
				for (k = 0; k < 3; k++)
				{
					/*
					// in 2D
					var i:int, sq:FLARSquare = FLARResult(results[k]).square;
					
					tool.graphics.lineStyle(0, 0xFF0000);
					for (i = 0; i < 4; i++)
					{
						var ix:int = sq.sqvertex[i].x;
						var iy:int = sq.sqvertex[i].y;
						tool.graphics.moveTo(ix - 3, iy + 0);
						tool.graphics.lineTo(ix + 4, iy + 0);
						tool.graphics.moveTo(ix + 0, iy - 3);
						tool.graphics.lineTo(ix + 0, iy + 4);
					}
					*/

					// or in 3D
					stuff[k].setTransformMatrix(FLARResult(results[k]).result);
				}
				
				// aggregate 3D results (this assumes all markers are oriented same way)
				A = FLARResult(results[2]);
				B = FLARResult(results[0]);
				C = FLARResult(results[1]);
				
				/*
				// aggregate 3D results (this assumes all markers are oriented same way)
				var _crrentPositionA:Vector3D = new Vector3D(A.result.m03, A.result.m13, A.result.m23);
				
				// not init yet
				if(!_positionA)
					_positionA = _crrentPositionA.clone();
				
				// near old pos?
				var isNear:Boolean = _positionA.nearEquals(_crrentPositionA,10,true);// && _objC.position.nearEquals(_sphereC.position,10,true); 
				if(isNear)
				{
					A = FLARResult(results[2]);
					B = FLARResult(results[0]);
					C = FLARResult(results[1]);
				}else{
					C = FLARResult(results[2]);
					B = FLARResult(results[0]);
					A = FLARResult(results[1]);
				}
				
				// store
				_positionA = new Vector3D(A.result.m03, A.result.m13, A.result.m23);
				*/
				
				var scale3:Number = (1 + B.distance / size) / 3;
				aggregate = new FLARTransMatResult;
				aggregate.m03 = (A.result.m03 + C.result.m03) * 0.5;
				aggregate.m13 = (A.result.m13 + C.result.m13) * 0.5;
				aggregate.m23 = (A.result.m23 + C.result.m23) * 0.5;
				aggregate.m00 = (A.result.m00 + B.result.m00 + C.result.m00) * scale3;
				aggregate.m10 = (A.result.m10 + B.result.m10 + C.result.m10) * scale3;
				aggregate.m20 = (A.result.m20 + B.result.m20 + C.result.m20) * scale3;
				aggregate.m01 = (A.result.m01 + B.result.m01 + C.result.m01) * scale3;
				aggregate.m11 = (A.result.m11 + B.result.m11 + C.result.m11) * scale3;
				aggregate.m21 = (A.result.m21 + B.result.m21 + C.result.m21) * scale3;
				aggregate.m02 = (A.result.m02 + B.result.m02 + C.result.m02) * scale3;
				aggregate.m12 = (A.result.m12 + B.result.m12 + C.result.m12) * scale3;
				aggregate.m22 = (A.result.m22 + B.result.m22 + C.result.m22) * scale3;
				
				// debug plane 
				stuff[3].setTransformMatrix(aggregate);
				
				_stuff = stuff[3];

				//try to debug normal
				//setTransform(_tempObject3D, aggregate);
				//trace(_tempObject3D.transform.matrix3D.
								
				if(!isDecoded)
				{
					// homography (I shall use 3D engine math - you can mess with FLARParam if you want to)
					var plane3D:Plane3D = Plane3D(_stuff.children[0]);
	
					// since 3D fit is not perfect, we shall grab some extra area
					plane3D.scaleX = plane3D.scaleY = plane3D.scaleZ = 1.05;
	
					// I call render() to init sandy matrices - you can do matrix math by hand and
					// not render a thing, or use better engine :-p~
					sandyScene.render();
					
					var face1:Polygon = Polygon(plane3D.aPolygons[0]);
					sandyScene.camera.projectArray(face1.vertices);
					var face2:Polygon = Polygon(plane3D.aPolygons[1]);
					sandyScene.camera.projectArray(face2.vertices);
	
					var p0:Point = new Point(face1.b.sx, face1.b.sy);
					var p1:Point = new Point(face1.a.sx, face1.a.sy);
					var p2:Point = new Point(face1.c.sx, face1.c.sy);
					var p3:Point = new Point(face2.b.sx, face2.b.sy);
	
					plane3D.scaleX = plane3D.scaleY = plane3D.scaleZ = 1.0;
	
					homography.fillRect(homography.rect, 0);
					homography.applyFilter(canvas, canvas.rect, canvas.rect.topLeft, new HomographyTransformFilter(240, 240, p0, p1, p2, p3));
	
					// now read QR code
					//qrInfo.text = "";
					qrResult.fillRect(qrResult.rect, 0);
					qrImage.process();
				}
			}else{
				//trace("new one?")
				//isDecoded = false;
			}
			/*
			setTransform(_sphereA, A.result);
			setTransform(_sphereB, B.result);
			setTransform(_sphereC, C.result);
			*/
			
			_sphereA.x = (stuff[0]).x;
			_sphereA.y = -(stuff[0]).y;
			_sphereA.z = (stuff[0]).z;
			
			if((stuff[1]).x< (stuff[2]).x)
			{
				_sphereB.x = (stuff[1]).x;
				_sphereB.y = -(stuff[1]).y;
				_sphereB.z = (stuff[1]).z;
				
				_sphereC.x = (stuff[2]).x;
				_sphereC.y = -(stuff[2]).y;
				_sphereC.z = (stuff[2]).z;
			}else{
				_sphereB.x = (stuff[2]).x;
				_sphereB.y = -(stuff[2]).y;
				_sphereB.z = (stuff[2]).z;
				
				_sphereC.x = (stuff[1]).x;
				_sphereC.y = -(stuff[1]).y;
				_sphereC.z = (stuff[1]).z;
			}
		}

		private var isSwap:Boolean = false;
		
		private var _positionA:Vector3D;
		private var _positionB:Vector3D;
		private var _positionC:Vector3D;
		
		private var _sphereA:Object3D;
		private var _sphereB:Object3D;
		private var _sphereC:Object3D;
		
		override protected function onInit():void
		{
			_sphereA = new Object3D();//Sphere(new WireColorMaterial(0xFF0000), 50, 4, 4);
			scene.addChild(_sphereA);
			
			_sphereB = new Object3D();//Sphere(new WireColorMaterial(0x00FF00), 50, 4, 4);
			scene.addChild(_sphereB);
			
			_sphereC = new Object3D();//Sphere(new WireColorMaterial(0x0000FF), 50, 4, 4);
			scene.addChild(_sphereC);
			
			//_sphereD = new Sphere(new WireColorMaterial(0xFF00FF), 50, 4, 4);
			//scene.addChild(_sphereD);
			
			//scene.addChild(_objA);
			//scene.addChild(_objB);
			//scene.addChild(_objC);
			
			view.x = 320/2;
			
			//_focus:Number = 100;
			//_zoom:Number = 10;
			
			view.setSize(320, 240);
			
			//camera.projection.fieldOfView = 36.438788936833824;
			camera.zoom = 6;
			camera.focus = 100;
			
			/*
			trace("---------------------------------");
			
			trace("focalLength	: "+camera.projection.focalLength);
			trace("fieldOfView	: "+camera.projection.fieldOfView);
			
			trace("focus		: "+camera.focus);
			trace("zoom			: "+camera.zoom);
			
			trace("---------------------------------");
			*/
			
			initCollada();
			
			initUser();
			
			initARQR();
		}
		
		private function setTransform(object3D:Object3D, m:FLARTransMatResult):void
		{
			object3D.transform.matrix3D = new Matrix3D(Vector.<Number>([
				 m.m00, m.m10, m.m20, 0,
				 m.m01, m.m11, m.m21, 0,
				 m.m02, m.m12, m.m22, 0,
				 m.m03, m.m13, m.m23, 1
			]));
		}
		
		private var aVector3D:Vector3D;
		private var bVector3D:Vector3D;
		private var cVector3D:Vector3D;
		
		private function onQRCodeRead(e:QRreaderEvent):void
		{
			// you don't have to draw qrResult, it's for debug ;)
			qrResult.draw(e.imageData, new Matrix(240 / e.imageData.width, 0, 0, 240 / e.imageData.height));

			qrDecoder.setQR(e.data);
			qrDecoder.startDecode();
		}

		private var isDecoded:Boolean = false;
		
		private function onQRDecoded(e:QRdecoderEvent):void
		{
			//qrInfo.text = "QR: " + e.data;
			//trace(e.data);
			title = "QR: " + e.data;
			
			// here is your chance to make changes to 3D scene
			//scene.render();
			
			isDecoded = true;
		}

		[Embed(source='../bin/112233.png')]
		private var ImageData:Class;
		
		[Embed(source='flar.dat',mimeType='application/octet-stream')]
		private var CameraData:Class;
		
		[Embed(source='flar.pat',mimeType='application/octet-stream')]
		private var MarkerData:Class;

		private var canvas:BitmapData;
		private var size:Number;
		private var param:FLARParam;
		private var code:FLARCode;
		private var raster:FLARRgbRaster_BitmapData;
		private var detector:FLARMultiMarkerDetector;

		private var sandyScene:Scene3D;
		private var stuff:Vector.<FLARBaseNode>;

		private var homography:BitmapData;

		private var qrImage:GetQRimage;
		private var qrDecoder:QRdecode;
		private var qrResult:BitmapData;

		//private var qrInfo:TextField;
	}
}