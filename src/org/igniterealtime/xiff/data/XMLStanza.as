/*
 * License
 */
package org.igniterealtime.xiff.data
{

	
	import org.igniterealtime.xiff.data.INodeProxy;
	import flash.xml.XMLNode;
	import flash.xml.XMLDocument;
	
	/**
	 * This is a base class for all classes that encapsulate XML stanza data. It provides
	 * a set of methods that faciliate easy manipulation of XML data.
	 * /Base Classes/2
	 */
	public class XMLStanza extends ExtensionContainer implements INodeProxy, IExtendable
	{
	    // Global factory for all XMLNode generation
		public static var XMLFactory:XMLDocument = new XMLDocument();
		private var myXML:XMLNode;
	
		public function XMLStanza()
		{
			super();
			myXML = XMLStanza.XMLFactory.createElement('');
		}
	
		/**
		 * A helper method to determine if a value is both not null
		 * and not undefined.
		 *
		 * @param	val The value to check for existance
		 * @return Whether the value checked is both not null and not undefined
		 */
		//private static function exists( val:* ):Boolean
		public static function exists( val:* ):Boolean
		{
			if( val != null && val !== undefined )
				return true;
			
			return false;
		}
	
		/**
		 * Adds a simple text node to the parent node specified.
		 *
		 * @param	parent The parent node that the newly created node should be appended onto
		 * @param	elementName The element name of the new node
		 * @param	value The value of the new node
		 * @return A reference to the new node
		 */
		public function addTextNode( parent:XMLNode, elementName:String, value:String):XMLNode
		{
			var newNode:XMLNode = XMLStanza.XMLFactory.createElement(elementName);
			newNode.appendChild(XMLFactory.createTextNode(value));
			parent.appendChild(newNode);
			return newNode;
		}
	
		/**
		 * Ensures that a node with a specific element name exists in the stanza. If it doesn't, then
		 * the node is created and returned.
		 *
		 * @param	node The node to ensure
		 * @param	elementName The element name to check for existance
		 * @return The node if it already exists, else a newly created node with the element name provided
		 */
		public function ensureNode( node:XMLNode, elementName:String ):XMLNode
		{
			if (!exists(node)) {
				node = XMLStanza.XMLFactory.createElement(elementName);
	            getNode().appendChild(node);
			}
			return node;
		}
	
		/**
		 * Replaces one node in the stanza with another simple text node.
		 *
		 * @param	parent The parent node to start at when searching for replacement
		 * @param	original The node to replace
		 * @param	elementName The new node's element name
		 * @param	value The new node's value
		 * @return The newly created node
		 */
		public function replaceTextNode( parent:XMLNode, original:XMLNode, elementName:String, value:String ):XMLNode
		{
			var newNode:XMLNode;
	
			// XXX Investigate on whether a remove/create is as efficient
			// as replacing the contents of the first text element nodeValue
			
			// Through the magic of AS, this will not fail if the 
			// original node is undefined
			
			//if (original == null) original = XMLStanza.XMLFactory.createElement('');
			if (original != null){
				original.removeNode();
			}
	
			if (exists(value)) {
				newNode = XMLStanza.XMLFactory.createElement(elementName);
				if (value.length > 0) {
					newNode.appendChild(XMLStanza.XMLFactory.createTextNode(value));
				}
				parent.appendChild(newNode);
			}
	
			return newNode;
		}
		
		/**
		 * @return	a reference to the stanza in XML form.
		 */
		public function getNode():XMLNode
		{
			return myXML;
		}
	
		/**
		 * Sets the XML node that should be used for this stanza's internal XML representation.
		 *
		 * @return Whether the node set was successful
		 */
		public function setNode( node:XMLNode ):Boolean
		{
			//var oldParent:XMLNode = (myXML.parentNode == null)?(XMLStanza.XMLFactory.createElement('')):(myXML.parentNode);
			var oldParent:XMLNode = myXML.parentNode;
			
			// Transfer ownership from the node's parent to our old parent
	
			myXML.removeNode();
			myXML = node;
	
			if (exists(myXML) && oldParent != null) {
				oldParent.appendChild(myXML);
			}
	
			return true;
		}
	}
}