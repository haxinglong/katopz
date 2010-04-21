package org.papervision3d.objects.parsers{	import com.adobe.images.PNGEncoder;	import com.adobe.serialization.json.JSON;	import com.cutecoma.game.core.IClip3D;		import flash.events.Event;	import flash.events.ProgressEvent;	import flash.net.URLLoader;	import flash.net.URLLoaderDataFormat;	import flash.net.URLRequest;	import flash.utils.ByteArray;	import flash.utils.Dictionary;	import flash.utils.getTimer;		import nochump.util.zip.ZipEntry;	import nochump.util.zip.ZipFile;		import org.papervision3d.core.animation.*;	import org.papervision3d.core.animation.channel.*;	import org.papervision3d.core.geom.renderables.*;	import org.papervision3d.core.proto.MaterialObject3D;	import org.papervision3d.core.render.data.RenderSessionData;	import org.papervision3d.materials.BitmapFileMaterial;	import org.papervision3d.objects.DisplayObject3D;
	/**	 * File loader for the MDJ file format. It's MD2, Texture,... in JSON format.	 *	 * @example	 * {	 * 	"paths" : ["modelPath/", "texturePath/],	 * 	"meshes" : ["model.md2"],	 * 	"textures" : ["model.png"]	 * }	 *	 * @author katopz@sleepydesign.com	 */	public class MDJ extends DisplayObject3D implements IAnimationDataProvider, IAnimatable, IClip3D	{		public var meshes:Vector.<MD2>;		protected var file:String;		protected var loader:URLLoader;		protected var loadScale:Number;		protected var _fps:int;		protected var _autoPlay:Boolean;		private var _materials:Dictionary;				private var _loadedMD2:int = 0;		private var _totalMD2:int = 0;		private function parse(data:*):void		{			var i:int = 0;			var _id:String;						var _json:JSON = new JSON();			var _models:Object = JSON.decode(data) as Object;						var _meshList:Array = _models.meshes;			var _materialList:Array = _models.textures;						// TODO : void null paths			_loadedMD2 = 0;			for (i = 0; i < _meshList.length; i++)			{				_totalMD2++;				var _md2:MD2 = new MD2(false);				_md2.addEventListener(Event.COMPLETE, onSuccess);				_md2.load(_models.paths[0] + _meshList[i], new BitmapFileMaterial(_models.paths[1] + _materialList[i]), _fps, loadScale);								_md2.name = String(_meshList[i]).split(".md2")[0];				_md2.name = _md2.name.slice(_md2.name.lastIndexOf("/") + 1);				_md2.name = _md2.name.split("_")[0];								this.addChild(_md2);			}		}		private function onSuccess(event:Event):void		{			var model:* = event.target;						if (!meshes)				meshes = new Vector.<MD2>();			meshes.fixed = false;			meshes.push(model);			meshes.fixed = true;			model.rotationZ = -90;			//model.material.doubleSided = false;			//addChild(model);						if(++_loadedMD2==_totalMD2)			{				var md2:MD2;								// reset				for each (md2 in meshes)					md2.stop();								if(_autoPlay)					for each (md2 in meshes)					md2.play();								visible = true;				dispatchEvent(new Event(Event.COMPLETE));			}		}		public function get fps():uint		{			return _fps;		}				public override function project(parent:DisplayObject3D, renderSessionData:RenderSessionData):Number		{			var realTimer:Number = getTimer();			for each (var md2:MD2 in meshes)				md2.groupTimer = realTimer;								return super.project(parent, renderSessionData);		}		public function play(clip:String = null):void		{			var _currentTime:Number = getTimer();			for each (var md2:MD2 in meshes)				md2.playByTime(clip, _currentTime);		}		public function stop():void		{			for each (var md2:MD2 in meshes)				md2.stop();		}		public function getAnimationChannelByName(name:String):AbstractChannel3D		{			return meshes[0].getAnimationChannelByName(name);		}		public function getAnimationChannels(target:DisplayObject3D = null):Array		{			return meshes[0].getAnimationChannels(target);		}		public function getAnimationChannelsByClip(name:String):Array		{			return meshes[0].getAnimationChannelsByClip(name);		}		public function load(asset:*, material:MaterialObject3D = null, fps:int = 30, scale:Number = 1):void		{			this.loadScale = scale;			this._fps = fps;			this.visible = false;			this.material = material || MaterialObject3D.DEBUG;			if (asset is ByteArray)			{				this.file = "";				parse(asset as ByteArray);			}			else			{				this.file = String(asset);				loader = new URLLoader();				loader.addEventListener(Event.COMPLETE, loadCompleteHandler);				loader.addEventListener(ProgressEvent.PROGRESS, loadProgressHandler);				try				{					loader.load(new URLRequest(this.file));				}				catch (e:Error)				{					//PaperLogger.error("error in loading MD2 file (" + this.file + ")");				}			}		}		protected function loadCompleteHandler(event:Event):void		{			var loader:URLLoader = event.target as URLLoader;			parse(loader.data);		}		protected function loadProgressHandler(event:ProgressEvent):void		{			dispatchEvent(event);		}		public function MDJ(autoPlay:Boolean = true):void		{			super();			_autoPlay = autoPlay;		}	}}