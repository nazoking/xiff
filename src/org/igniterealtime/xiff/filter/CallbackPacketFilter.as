/*
 * License
 */
package org.igniterealtime.xiff.filter
{
	import org.igniterealtime.xiff.data.XMPPStanza;
	import org.igniterealtime.xiff.util.Callback;

	public class CallbackPacketFilter implements IPacketFilter
	{
		private var _filterFunction:Function;
		private var _callback:Callback;
		private var _processFunction:Function;
		
		/**
		 * 
		 * @param	callback
		 * @param	filterFunction
		 * @param	processFunction
		 */
		public function CallbackPacketFilter(callback:Callback, filterFunction:Function = null, processFunction:Function = null)
		{
			_callback = callback;
			_filterFunction = filterFunction;
			_processFunction = processFunction;
		}
		
		public function accept(packet:XMPPStanza):void
		{
			if (_filterFunction == null || _filterFunction(packet)) 
			{
				var processed:Object = packet;
				if (_processFunction != null) 
				{
					processed = _processFunction(packet);
				}
				_callback.call(processed);
			}
		}
		
	}
}