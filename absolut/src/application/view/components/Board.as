package application.view.components
{
	import application.model.CrystalDataProxy;
	import application.model.Rules;

	import com.greensock.TweenLite;
	import com.sleepydesign.core.CommandManager;
	import com.sleepydesign.display.SDSprite;

	import flash.events.MouseEvent;
	import flash.geom.Point;

	import org.osflash.signals.Signal;

	public class Board extends SDSprite
	{
		// signal
		public var moveSignal:Signal = new Signal();

		// status
		private const SELECT_FOCUS:String = "SELECT_FOCUS";
		private const SELECT_SWAP:String = "SELECT_SWAP";
		private var _status:String = SELECT_FOCUS;

		// view
		private var _canvas:SDSprite;

		// focus
		private var _focusCrystal:Crystal;

		public function get focusCrystal():Crystal
		{
			return _focusCrystal;
		}

		private var _swapCrystal:Crystal;

		public function get swapCrystal():Crystal
		{
			return _swapCrystal;
		}

		public function get _crystals():Vector.<Crystal>
		{
			return CrystalDataProxy._crystals;
		}

		public function set _crystals(value:Vector.<Crystal>):void
		{
			CrystalDataProxy._crystals = value;
		}

		private var _enabled:Boolean;

		public function get enabled():Boolean
		{
			return _enabled;
		}

		public function set enabled(value:Boolean):void
		{
			_enabled = _canvas.mouseEnabled = _canvas.mouseChildren = value;
		}

		public function Board()
		{
			// canvas
			addChild(_canvas = new SDSprite());

			for each (var _crystal:Crystal in _crystals)
				_canvas.addChild(_crystal);

			addEventListener(MouseEvent.CLICK, onClick);
		}

		public function onClick(event:MouseEvent):void
		{
			// click on crystal
			if (event.target.parent is Crystal)
			{
				var _crystal:Crystal = event.target.parent;
				if (_crystal)
					setFocusCrystal(_crystal);
			}
		}

		private function setFocusCrystal(_crystal:Crystal):void
		{
			// click on crystal
			if (_crystal)
			{
				enabled = false;
				switch (_status)
				{
					case SELECT_FOCUS:

						// click on old crystal
						_crystal.focus = !_crystal.focus;

						// mark as focus
						_focusCrystal = _crystal;

						// wait for next click
						enabled = true;

						_status = SELECT_SWAP;

						break;

					case SELECT_SWAP:

						// click on old crystal
						if (_focusCrystal == _crystal)
						{
							_crystal.focus = !_crystal.focus;
							_focusCrystal = null;
							_status = SELECT_FOCUS;
							enabled = true;

							return;
						}

						// rule #1 : nearby?
						if (!Rules.hasNeighbor(_focusCrystal.id, _crystal.id))
						{
							// refocus
							_focusCrystal.focus = !_focusCrystal.focus;
							_status = SELECT_FOCUS;
							setFocusCrystal(_crystal);
						}
						else
						{
							// click on other crystal
							_crystal.focus = !_crystal.focus;

							// already mark?
							if (_focusCrystal)
							{
								// will swap focus crystal with this one
								_swapCrystal = _crystal;

								// swap both
								showSwapEffect(_focusCrystal, _swapCrystal, onSwapComplete);
							}
						}
						break;
				}
			}
		}

		private function showSwapEffect(_focusCrystal:Crystal, _swapCrystal:Crystal, callBack:Function):void
		{
			var _commandManager:CommandManager = new CommandManager(true);
			_commandManager.addCommand(new SwapCrystalEffect(_focusCrystal, _swapCrystal));
			_commandManager.addCommand(new SwapCrystalEffect(_swapCrystal, _focusCrystal));
			_commandManager.completeSignal.addOnce(callBack);
			_commandManager.start();
		}

		private function onSwapComplete():void
		{
			trace(" ! onSwapComplete");
			CrystalDataProxy.swapByID(_crystals, _focusCrystal.id, _swapCrystal.id);

			trace(" > Begin Check condition...");
			onCheckComplete(Rules.isSameColorRemain(_crystals));
		}

		private function onCheckComplete(result:Boolean):void
		{
			trace(" < End Check condition...");
			if (result)
			{
				// good move
				trace(" * Call good effect");
				doGoodEffect();
			}
			else
			{
				// bad move
				trace(" ! Bad move");
				showSwapEffect(_focusCrystal, _swapCrystal, onBadMoveComplete);

				// swap back
				CrystalDataProxy.swapByID(_crystals, _focusCrystal.id, _swapCrystal.id);
			}
		}

		private function doGoodEffect():void
		{
			trace(" > Begin Effect");
			var _commandManager:CommandManager = new CommandManager(true);
			for each (var _crystal:Crystal in _crystals)
				if (_crystal.status == CrystalStatus.TOBE_REMOVE)
					_commandManager.addCommand(new HideCrystalEffect(_crystal));
			_commandManager.completeSignal.addOnce(onGoodMoveComplete);
			_commandManager.start();
		}

		private function onGoodMoveComplete():void
		{
			trace(" < End Effect");
			refill();
		}

		private var _fillEffect:CommandManager = new CommandManager(true);

		private function refill():void
		{
			trace(" > Begin Refill");

			var _crystal:Crystal
			var _index:int = _crystals.length;

			// from bottom to top
			while (--_index > -1)
			{
				_crystal = _crystals[_index];

				// it's removed
				if (_crystal.status == CrystalStatus.REMOVED || _crystal.status == CrystalStatus.MOVE)
				{
					if (!_crystal.prevPoint)
						_crystal.prevPoint = new Point(_crystal.x, _crystal.y);

					// find top most to replace
					var _aboveCrystal:Crystal = CrystalDataProxy.getAboveCrystal(_crystals, _index, Rules.COL_SIZE);
					if (_aboveCrystal)
					{
						// fall to bottom
						_crystal.swapID = _aboveCrystal.id;

						_aboveCrystal.status = CrystalStatus.MOVE;
						if (!_aboveCrystal.prevPoint)
							_aboveCrystal.prevPoint = new Point(_aboveCrystal.x, _aboveCrystal.y);

						_crystal.status = CrystalStatus.READY;
						onRefillComplete(_crystal);
					}
					else
					{
						// stable position wait for reveal
						_crystal.alpha = 1;
						_crystal.spin();

						_crystal.status = CrystalStatus.READY;
						_crystal.swapID = -1;
						onRefillComplete(_crystal);
					}
				}
			}
		}

		private function onRefillComplete(_crystal:Crystal):void
		{
			// real swap
			if (_crystal.swapID != -1)
			{
				CrystalDataProxy.swapPositionByID(_crystals, _crystal.id, _crystal.swapID);
				_crystal.prevPoint = new Point(_crystals[_crystal.swapID].x, _crystals[_crystal.swapID].y);
				CrystalDataProxy.swapByID(_crystals, _crystal.id, _crystal.swapID);

				_crystal.swapID = -1;
			}

			onMoveComplete();
		}

		private function onMoveComplete():void
		{
			// all clean?
			var _length:int = _crystals.length;
			while (--_length > -1 && (_crystals[_length].status == CrystalStatus.READY))
			{
				//
			}
			if (_length > -1)
				return;

			trace(" < End Refill");

			// begin effect
			_fillEffect.stop();
			_fillEffect.completeSignal.removeAll();

			for each (var _crystal:Crystal in _crystals)
			{
				if (!_crystal.prevPoint)
					continue;

				_crystal.nextPoint = new Point(_crystal.x, _crystal.y);

				if (_crystal.prevPoint.y < _crystal.nextPoint.y)
				{
					// do effect only falling
					_crystal.x = _crystal.prevPoint.x;
					_crystal.y = _crystal.prevPoint.y;
					_fillEffect.addCommand(new MoveCrystalEffect(_crystal));
				}
				else if (_crystal.prevPoint)
				{
					// swap from bottom? make it higher
					_crystal.x = _crystal.nextPoint.x;
					_crystal.y = -_crystal.nextPoint.y - Crystal.SIZE;
					_fillEffect.addCommand(new MoveCrystalEffect(_crystal));
				}
			}

			_fillEffect.completeSignal.addOnce(onMoveEffectComplete);
			_fillEffect.start();
		}

		private function onMoveEffectComplete():void
		{
			trace(" > Begin Recheck");
			reCheck(Rules.isSameColorRemain(_crystals));
		}

		private function reCheck(result:Boolean):void
		{
			if (result)
			{
				onCheckComplete(result);
			}
			else
			{
				trace(" < End ReCheck");
				trace(" > Begin Game over check");
				if (!Rules.isOver(_crystals))
				{
					trace(" < End Game over check");
					nextTurn();
				}
				else
				{
					trace(" < Game Over!");
				}
			}
		}

		private function onBadMoveComplete():void
		{
			// dispose
			_focusCrystal = _swapCrystal = null;
			nextTurn();
		}

		private function nextTurn():void
		{
			trace(" ! nextTurn");
			
			// dispose
			_focusCrystal = _swapCrystal = null;

			// accept inpt
			enabled = true;
			_status = SELECT_FOCUS;
		}

		override public function destroy():void
		{
			removeEventListener(MouseEvent.CLICK, onClick);
			_focusCrystal = _swapCrystal = null;
			super.destroy();
		}
	}
}

import application.model.CrystalDataProxy;
import application.view.components.Crystal;
import application.view.components.CrystalStatus;

import com.greensock.TweenLite;
import com.sleepydesign.core.SDCommand;

import flash.geom.Point;

internal class HideCrystalEffect extends SDCommand
{
	private var _crystal:Crystal;

	public function HideCrystalEffect(crystal:Crystal)
	{
		_crystal = crystal;
	}

	override public function doCommand():void
	{
		TweenLite.to(_crystal, .25, {alpha: 0, onComplete: super.doCommand});
	}

	override public function command():void
	{
		_crystal.status = CrystalStatus.REMOVED;
	}
}

internal class SwapCrystalEffect extends SDCommand
{
	private var _position:Point;
	private var _focusCrystal:Crystal;

	public function SwapCrystalEffect(focusCrystal:Crystal, swapCrystal:Crystal)
	{
		_focusCrystal = focusCrystal;
		_position = new Point(swapCrystal.x, swapCrystal.y);
	}

	override public function doCommand():void
	{
		TweenLite.to(_focusCrystal, .5, {x: _position.x, y: _position.y, onComplete: super.doCommand});
	}

	override public function command():void
	{
		_focusCrystal.focus = false;
	}
}

internal class MoveCrystalEffect extends SDCommand
{
	private var _crystal:Crystal;

	public function MoveCrystalEffect(crystal:Crystal)
	{
		_crystal = crystal;
	}

	override public function doCommand():void
	{
		TweenLite.to(_crystal, 0.5 * 1000 / Math.abs(_crystal.nextPoint.y - _crystal.y) / Crystal.SIZE, {alpha:1, x:_crystal.nextPoint.x, y:_crystal.nextPoint.y, onComplete: super.doCommand});
	}

	override public function command():void
	{
		_crystal.prevPoint = _crystal.nextPoint = null;
	}
}