﻿package com.sleepydesign.game.core
{
	import com.sleepydesign.core.SDObject;
	
	public class AbstractCharacter extends SDObject
	{
		//public var data			: PlayerData;
		
		public var id			: String;
		public var _instance		: *;
		public var model		: SDModel;
		
		public var height		: Number = 0;
		
		/*
		public var _clip			: DisplayObject3D;
		
		public function get clip():DisplayObject3D
		{
			return _clip;
		}
		
		public function set clip(value:DisplayObject3D):void
		{
			_clip = value;
		}
		*/
		
		public var type			: String;
		
		//public var director		: * ;
		
		public function AbstractCharacter(id:String=null)//, instance:DisplayObject3D=null)
		{
			this.id = id?id:String(new Date().valueOf());
			_instance = _instance?_instance: new Object();
			
			super();
		}
	}
}