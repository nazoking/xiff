/*
 * License
 */
package org.igniterealtime.xiff.data.muc
{
	import flash.xml.XMLNode;
	
	import org.igniterealtime.xiff.core.EscapedJID;
	import org.igniterealtime.xiff.data.IExtension;
	
	/**
	 * Implements the administration command data model in <a href="http://xmpp.org/extensions/xep-0045.html">XEP-0045<a> for multi-user chat.
	 *
	 * @see http://xmpp.org/extensions/xep-0045.html
	 */
	public class MUCOwnerExtension extends MUCBaseExtension implements IExtension
	{
		// Static class variables to be overridden in subclasses;
		public static const NS:String = "http://jabber.org/protocol/muc#owner";
		public static const ELEMENT:String = "query";
	
		private var _destroyNode:XMLNode;
	
		/**
		 * 
		 * @param	parent (Optional) The containing XMLNode for this extension
		 */
		public function MUCOwnerExtension( parent:XMLNode=null )
		{
			super(parent);
		}
	
		public function getNS():String
		{
			return MUCOwnerExtension.NS;
		}
	
		public function getElementName():String
		{
			return MUCOwnerExtension.ELEMENT;
		}
	
		override public function deserialize( node:XMLNode ):Boolean
		{
			super.deserialize(node);
	
			var children:Array = node.childNodes;
			for( var i:String in children ) {
				switch( children[i].nodeName )
				{
					case "destroy":
						_destroyNode = children[i];
						break;
				}
			}
			return true;
		}
	
	    override public function serialize( parent:XMLNode ):Boolean
	    {
	        return super.serialize(parent);
	    }
	
	    /**
	     * Replaces the <code>destroy</code> node with a new node and sets
	     * the <code>reason</code> element and <code>jid</code> attribute
	     *
	     * @param	reason A string describing the reason for room destruction
	     * @param	alternateJID A string containing a JID that room members can use instead of this room
	     * availability Flash Player 7
	     */
	    public function destroy(reason:String, alternateJID:EscapedJID):void
	    {
	        _destroyNode = ensureNode(_destroyNode, "destroy");
	        for each(var child:XMLNode in _destroyNode.childNodes)
			{
	            child.removeNode();
	        }
	
	        if( exists(reason) ) { replaceTextNode(_destroyNode, undefined, "reason", reason); }
	        if( exists(alternateJID) ) { _destroyNode.attributes.jid = alternateJID.toString(); }
	    }
	}
}
