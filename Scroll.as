package 
{
	import com.greensock.TweenMax;
	import com.greensock.easing.*;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	public class Scroll extends Sprite
	{
		private var window:Sprite;//窗口
		private var line:Sprite;//滑动槽
		private var bar:Sprite;//滑动条按钮
		private var rect:Rectangle;//滑动按钮活动范围
		private var thisStage:MovieClip;

		public var content:MovieClip;//被拖动的内容
		public var tweenValue:Number = 0.5;//缓动值

		public var content_num:int;

		public var thumb_arr:Array;

		private var current_thumb:MovieClip;
		public var current_click_index:int;
		var move_timer:Timer;

		//构造函数传入stage和四个影片剪辑皮肤(左上角注册点)，分别是内容、窗口、滑槽、滑动按钮。
		public function Scroll(_stage:MovieClip,_content:MovieClip, _window:Sprite, _line:Sprite, _bar:Sprite,stage:Stage)
		{
			thisStage = _stage;
			content = _content;
			window = _window;
			line = _line;
			bar = _bar;
			thisStage.addChildAt(content,0);
			thisStage.addChildAt(window,0);
			thisStage.addChildAt(bar,0);
			thisStage.addChildAt(line,0);

			content_num = 0;
			thumb_arr=new Array();
			move_timer = new Timer(1000);

			rect = new Rectangle(line.x,line.y,0,line.height - bar.height);//约束拖动范围
			content.mask = window;//遮罩
			bar.addEventListener(MouseEvent.MOUSE_DOWN,mouseHd);
			stage.addEventListener(MouseEvent.MOUSE_UP,mouseHd);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onWhellScroll);

			stage.addEventListener(MouseEvent.MOUSE_UP, onUp);

		}
		//鼠标移动或弹起时的逻辑
		private function mouseHd(e:MouseEvent):void
		{
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				bar.startDrag(false,rect);
				stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHd);
			}
			else
			{
				bar.stopDrag();
				stage.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHd);
			}
		}
		//获取当前滚动条的位置
		public function getBarY(content_height:Number):Number
		{
			return (window.y-content.y)/((content_height-window.height)/(line.height-bar.height))+line.y;
		}
		//鼠标移动时的逻辑
		private function mouseMoveHd(e:MouseEvent=null):void
		{
			var newY:Number=window.y-(bar.y-line.y)*((content.height-window.height)/(line.height-bar.height));
			
			if (tweenValue > 0)
			{
				TweenMax.to(content, tweenValue, { y:newY} );
			}
			else
			{
				content.y = newY;
			}
			
			trace(newY+"===="+currentTopIndex());
			
		}
		//刷新
		public function upDate()
		{
			mouseMoveHd();
		}

		//滚动到底
		public function toBottom()
		{
			bar.y = line.height - bar.height;
			upDate();
		}
		
		//向上滚动n格
		public function moveUp(n:int=1)
		{
			//line.height-bar.height为bar可以移动的范围
			
			//content.height-window.height为
			
			
			bar.y=bar.y-150*(line.height-bar.height)/(content.height-window.height)*n;
			if (bar.y < 0)
			{
				bar.y = 0;
			}
			upDate();
		}
		//向下滚动n格
		public function moveDown(n:int=1)
		{
			if ((content.height-window.height)!=0)
			{
				bar.y=bar.y+150*(line.height-bar.height)/(content.height-window.height)*n;
			}
			else
			{
				bar.y = line.height - bar.height;
			}
			if (bar.y > line.height - bar.height)
			{
				bar.y = line.height - bar.height;
			}
			upDate();
		}
		
		public function moveToIndex(n:int)
		{
			var current_n:int=currentTopIndex();
			trace("top index:"+currentTopIndex());
			
			if(n-(current_n+1)>0)
			{
				moveDown(n-(current_n+1));
			}
			else
			{
				moveUp(current_n+1-n);
			}
			
			setThumbFocus(n);
		}

		//添加元素
		public function addContent(thumb:MovieClip)
		{
			content.addChild(thumb);
			thumb.y = content_num * 150 + 5;
			thumb.x = 5;

			thumb.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			thumb_arr.push(thumb);
			thumb.index = content_num;

			content_num++;

			if (current_thumb)
			{
				current_thumb.spark.visible = false;
			}
			thumb.spark.visible = true;
			current_thumb = thumb;
		}
		
		//设置当前Thumb
		public function setThumbFocus(i:int)
		{
			if(current_thumb)
			{
				current_thumb.spark.visible = false;
			}
			thumb_arr[i].spark.visible = true;
			current_thumb=thumb_arr[i];
			current_click_index=i;
			
		}
		
		
		//获取顶部的Thumb的index
		public function currentTopIndex():int
		{
			var i:int;
			for(i=0;i<content_num;i++)
			{
				var abs_y:Number;
				if(content.y>0)
				{
					abs_y=0;
				}
				else
				{
					abs_y=Math.abs(content.y)
				}
				
				if(abs_y<150*(i+1)-5)
				{
					return i;
				}				
			}
			return i;
		}
		
		//获取当前被点击的图标的Index
		public function currentThumbIndex()
		{
			return current_click_index;
		}

		//滚轮操作;
		private function onWhellScroll(e:MouseEvent)
		{

			if (e.delta > 0)
			{
				//up
				moveUp();
			}
			else
			{
				//down
				moveDown();
			}
		}


		//点击缩略图时的逻辑
		function onDown(e:MouseEvent)
		{
			if (current_thumb)
			{
				current_thumb.spark.visible = false;
			}
			current_thumb = BmpThumb(e.currentTarget);

			current_thumb.spark.visible = true;

			current_click_index = current_thumb.index;
			
			trace(current_click_index);		

			var bounds:Rectangle = new Rectangle(5,-140,0,10000000);
			content.setChildIndex(current_thumb, content.numChildren - 1);
			current_thumb.alpha = 0.5;
			current_thumb.startDrag(false, bounds);
			move_timer.addEventListener(TimerEvent.TIMER, onMoveTimer);
			move_timer.start();
			current_thumb.addEventListener(MouseEvent.MOUSE_MOVE, onMyMouseMove);
			bar.addEventListener(Event.ENTER_FRAME, onBarFrame);
		}

		//拖动条进行移动;
		function onBarFrame(e:Event)
		{
			bar.y = getBarY((thumb_arr.length - 1) * 150 + 145);
		}

		//拖动时，结束所有的动画
		function onMyMouseMove(e:MouseEvent)
		{
			TweenMax.killTweensOf(current_thumb);
			TweenMax.killTweensOf(content);
		}

		//拖动缩略图，移动到边缘时，自动滚动逻辑
		function onMoveTimer(e:TimerEvent)
		{
			var pos:Point = new Point(current_thumb.x,current_thumb.y);

			var cur_y:Number = content.localToGlobal(pos).y;
			if (cur_y < 0)
			{
				if (current_thumb.y - 150 > 0)
				{
					TweenMax.to(current_thumb, 0.5, {y: current_thumb.y - 150});
					TweenMax.to(content, 0.5, {y: content.y + 150});
				}
				else
				{
					TweenMax.to(current_thumb, 0.5, {y: 0});
					TweenMax.to(content, 0.5, {y: 0});
				}
			}

			if (cur_y > 435)
			{
				if (coor2index(current_thumb.y) < thumb_arr.length - 1)
				{
					TweenMax.to(current_thumb, 0.5, {y: current_thumb.y + 150});
					TweenMax.to(content, 0.5, {y: content.y - 150});
				}
			}
		}


		//将坐标转换为索引
		function coor2index(y:Number):int
		{
			var index:int = Math.floor((y - 5) / 150);
			if (index < 0)
			{
				index = -1;
			}
			if (index > thumb_arr.length - 1)
			{
				index = thumb_arr.length - 1;
			}
			return index;
		}

		//将索引转换为坐标
		function index2coor(index:int):Number
		{
			return index * 150 + 5;
		}


		//获取停止拖动时，缩略图应该回到的位置
		function setStopDragPosition(cur_y:Number):Number
		{
			var ori_index = current_thumb.index;
			var cur_index:int;
			if (index2coor(ori_index - 1) < cur_y < index2coor(ori_index + 1))
			{
				cur_index = ori_index;
			}
			if (cur_y >= index2coor(ori_index + 1))
			{
				cur_index = coor2index(cur_y);
			}
			if (cur_y <= index2coor(ori_index - 1))
			{
				cur_index = coor2index(cur_y) + 1;
			}
			return index2coor(cur_index);
		}

		//鼠标弹起时，对缩略图进行放置
		function onUp(e:MouseEvent)
		{

			if (current_thumb)
			{
				var ori_index = current_thumb.index;

				current_thumb.alpha = 1;
				current_thumb.stopDrag();
				var desti_y:Number = setStopDragPosition(current_thumb.y);
				TweenMax.to(current_thumb, 0.5, {y: desti_y});

				var cur_index = coor2index(desti_y);
				moveThumbAmimation(ori_index, cur_index);
				move_timer.removeEventListener(TimerEvent.TIMER, onMoveTimer);
				current_thumb.removeEventListener(MouseEvent.MOUSE_MOVE, onMyMouseMove);
				bar.removeEventListener(Event.ENTER_FRAME, onBarFrame);
			}
		}

		//对所有缩略图进行移动;
		function moveThumbAmimation(ori_index:int, cur_index:int)
		{
			var i:int;
			var tmp:BmpThumb;
			//var tmp_url:String;

			if (ori_index < cur_index)
			{
				tmp = thumb_arr[ori_index];
				//tmp_url = url_arr[ori_index];
				for (i = ori_index + 1; i <= cur_index; i++)
				{
					TweenMax.to(thumb_arr[i], 0.5, {y: BmpThumb(thumb_arr[i]).y - 150});
					thumb_arr[i - 1] = thumb_arr[i];
					thumb_arr[i - 1].index = i - 1;
					//url_arr[i - 1] = thumb_arr[i];
				}
				thumb_arr[cur_index] = tmp;
				thumb_arr[cur_index].index = cur_index;
				//url_arr[cur_index] = tmp_url;
			}
			if (ori_index > cur_index)
			{
				tmp = thumb_arr[ori_index];
				//tmp_url = url_arr[ori_index];
				for (i = ori_index - 1; i >= cur_index; i--)
				{
					TweenMax.to(thumb_arr[i], 0.5, {y: thumb_arr[i].y + 150});
					thumb_arr[i + 1] = thumb_arr[i];
					thumb_arr[i + 1].index = i + 1;
					//url_arr[i + 1] = thumb_arr[i];
				}
				thumb_arr[cur_index] = tmp;
				thumb_arr[cur_index].index = cur_index;
				//url_arr[cur_index] = thumb_arr[cur_index];
			}
		}


	}
}