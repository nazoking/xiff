/*
 * License
 */
package org.igniterealtime.xiff.core
{
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.XMLSocket;
	import flash.utils.Timer;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import mx.logging.ILogger;
	
	import org.igniterealtime.xiff.auth.Anonymous;
	import org.igniterealtime.xiff.auth.External;
	import org.igniterealtime.xiff.auth.Plain;
	import org.igniterealtime.xiff.auth.SASLAuth;
	import org.igniterealtime.xiff.data.Extension;
	import org.igniterealtime.xiff.data.IExtension;
	import org.igniterealtime.xiff.data.IQ;
	import org.igniterealtime.xiff.data.Message;
	import org.igniterealtime.xiff.data.Presence;
	import org.igniterealtime.xiff.data.XMPPStanza;
	import org.igniterealtime.xiff.data.auth.AuthExtension;
	import org.igniterealtime.xiff.data.bind.BindExtension;
	import org.igniterealtime.xiff.data.forms.FormExtension;
	import org.igniterealtime.xiff.data.register.RegisterExtension;
	import org.igniterealtime.xiff.data.session.SessionExtension;
	import org.igniterealtime.xiff.events.*;
	import org.igniterealtime.xiff.exception.SerializationException;
	import org.igniterealtime.xiff.logging.LoggerFactory;

	/**
	 * Dispatched when a password change is successful.
	 *
	 * @eventType org.igniterealtime.xiff.events.ChangePasswordSuccessEvent.PASSWORD_SUCCESS
	 */
    [Event(name="changePasswordSuccess", type="org.igniterealtime.xiff.events.ChangePasswordSuccessEvent")]

    /**
     * Dispatched when the connection is successfully made to the server.
     *
     * @eventType org.igniterealtime.xiff.events.ConnectionSuccessEvent.CONNECT_SUCCESS
     */
    [Event(name="connection", type="org.igniterealtime.xiff.events.ConnectionSuccessEvent")]

    /**
     * Dispatched when there is a disconnection from the server.
     *
     * @eventType org.igniterealtime.xiff.events.DisconnectionEvent.DISCONNECT
     */
    [Event(name="disconnection", type="org.igniterealtime.xiff.events.DisconnectionEvent")]

    /**
     * Dispatched when there is some type of XMPP error.
     *
     * @eventType org.igniterealtime.xiff.events.XIFFErrorEvent.XIFF_ERROR
     */
    [Event(name="error", type="org.igniterealtime.xiff.events.XIFFErrorEvent")]

    /**
     * Dispatched whenever there is incoming XML data.
     *
     * @eventType org.igniterealtime.xiff.events.IncomingDataEvent.INCOMING_DATA
     */
    [Event(name="incomingData", type="org.igniterealtime.xiff.events.IncomingDataEvent")]

    /**
     * Dispatched on successful authentication (login) with the server.
     *
     * @eventType org.igniterealtime.xiff.events.LoginEvent.LOGIN
     */
    [Event(name="login", type="org.igniterealtime.xiff.events.LoginEvent")]

    /**
     * Dispatched on incoming messages.
     *
     * @eventType org.igniterealtime.xiff.events.MessageEvent.MESSAGE
     */
    [Event(name="message", type="org.igniterealtime.xiff.events.MessageEvent")]

    /**
     * Dispatched whenever data is sent to the server.
     *
     * @eventType org.igniterealtime.xiff.events.OutgoingDataEvent.OUTGOING_DATA
     */
    [Event(name="outgoingData", type="org.igniterealtime.xiff.events.OutgoingDataEvent")]

    /**
     * Dispatched on incoming presence data.
     *
     * @eventType org.igniterealtime.xiff.events.PresenceEvent.PRESENCE
     */
    [Event(name="presence", type="org.igniterealtime.xiff.events.PresenceEvent")]

    /**
     * Dispatched on when new user account registration is successful.
     *
     * @eventType org.igniterealtime.xiff.events.RegistrationSuccessEvent.REGISTRATION_SUCCESS
     */
    [Event(name="registrationSuccess", type="org.igniterealtime.xiff.events.RegistrationSuccessEvent")]

    /**
     * This class is used to connect to and manage data coming from an XMPP server. Use one instance
     * of this class per connection.
     */
	public class XMPPConnection extends EventDispatcher
	{
		private static const logger:ILogger = LoggerFactory.getLogger("org.igniterealtime.xiff.core.XMPPConnection");
			
		/**
		 * @private
		 */
		protected var _useAnonymousLogin:Boolean = false;
		
		/**
		 * @private
		 */
		protected var _socket:XMLSocket;
		
		/**
		 * @private
		 */
		protected var myServer:String;
		
		/**
		 * @private
		 */
	 	protected var myDomain:String;
		
		/**
		 * @private
		 */
		protected var myUsername:String;
		
		/**
		 * @private
		 */
		protected var myResource:String = "xiff";
		
		/**
		 * @private
		 */
		protected var myPassword:String;
	
		/**
		 * @private
		 */
		protected var myPort:Number = 5222;
		
		/**
		 * @see http://xmpp.org/extensions/xep-0138.html
		 */
		protected var _compress:Boolean = false;
		
		/**
		 * @private
		 */
		protected var _active:Boolean;
		
		/**
		 * @private
		 */
		protected var loggedIn:Boolean = false;
		
		/**
		 * @private
		 */
		protected var ignoreWhitespace:Boolean = true;
		
		/**
		 * @private
		 */
		protected var openingStreamTag:String;
		
		/**
		 * @private
		 */
		protected var closingStreamTag:String;

		/**
		 * @private
		 */
		protected var sessionID:String;
		
		/**
		 * Hash to hold callbacks for IQs
		 * @private
		 */
		protected var pendingIQs:Object = { };
		
		/**
		 * @private
		 */
		protected var _expireTagSearch:Boolean;
		
		/**
		 * @private
		 */
		protected var auth:SASLAuth;
		
		protected static var _openConnections:Array = [];
		
		/**
		 * The types of SASL mechanisms available.
		 * @see org.igniterealtime.xiff.auth.Anonymous
		 * @see org.igniterealtime.xiff.auth.External
		 * @see org.igniterealtime.xiff.auth.Plain
		 */
		protected static var saslMechanisms:Object = {
			"PLAIN": Plain,
			"ANONYMOUS": Anonymous,
			"EXTERNAL": External
		};
		
		public function XMPPConnection()
		{
			active = false;
			
			AuthExtension.enable();
			BindExtension.enable();
			SessionExtension.enable();
			RegisterExtension.enable();
			FormExtension.enable();
		}
		
		/**
		 * Connects to the server.
		 * Possible options are:
		 * <ul>
		 * <li>flash</li>
		 * <li>terminatedFlash</li>
		 * <li>standard</li>
		 * <li>terminatedStandard (default)</li>
		 * </ul>
		 * Some servers, like Jabber, Inc.'s XCP and Jabberd 1.4 expect &lt;flash:stream&gt; from
		 * a Flash client instead of the standard &lt;stream:stream&gt;.
		 *
		 * @param	streamType (Optional) The type of initial stream negotiation, either &lt;flash:stream&gt; or &lt;stream:stream&gt;.
		 *
		 * @return A boolean indicating whether the server was found.
		 */
		public function connect( streamType:String = "terminatedStandard" ):Boolean
		{
			_socket = _createXmlSocket();
			
			active = false;
			loggedIn = false;
			
			chooseStreamTags(streamType);
			
			_socket.connect( server, port );
			return true;
		}
		
		/**
		 *
		 * @param	name
		 * @param	authClass
		 */
		public static function registerSASLMechanism(name:String, authClass:Class):void
		{
			saslMechanisms[name] = authClass;
		}
		
		public static function disableSASLMechanism(name:String):void
		{
			saslMechanisms[name] = null;
		}
		
		/**
		 * Disconnects from the server if currently connected. After disconnect,
		 * a <code>DisconnectionEvent.DISCONNECT</code> event is broadcast.
		 */
		public function disconnect():void
		{
			if( isActive() ) {
				sendXML( closingStreamTag );
				if(_socket)
					_socket.close();
				active = false;
				loggedIn = false;
				var event:DisconnectionEvent = new DisconnectionEvent();
				dispatchEvent(event);
			}
		}
		
		/**
		 * Sends data to the server. If the data to send cannot be serialized properly, 
		 * this method throws a <code>SerializeException</code>.
		 *
		 * @param	o The data to send. This must be an instance of a class that implements the ISerializable interface.
		 * @see	org.igniterealtime.xiff.data.ISerializable
		 * @example	The following example sends a basic chat message to the user with the JID "sideshowbob@springfieldpenitentiary.gov".<br />
		 * <pre>var msg:Message = new Message( "sideshowbob@springfieldpenitentiary.gov", null, "Hi Bob.", "<b>Hi Bob.</b>", Message.CHAT_TYPE );
		 * myXMPPConnection.send( msg );</pre>
		 */
		public function send( o:XMPPStanza ):void
		{
			if( isActive() ) {
				if( o is IQ ) {
	                var iq:IQ = o as IQ;
	                if ((iq.callbackName != null && iq.callbackScope != null) || iq.callback != null)
	                {
	                	addIQCallbackToPending( iq.id, iq.callbackName, iq.callbackScope, iq.callback );
	                }
				}
				var root:XMLNode = o.getNode().parentNode;
				if (root == null) {
					root = new XMLDocument();
				}
	
				if (o.serialize(root)) {
					sendXML( root.firstChild );
				} else {
					throw new SerializationException();
				}
			}
		}
		
		public function sendKeepAlive():void
		{
			if( isActive() ) {
				sendXML(" ");
			}
		}
		
		/**
		 * Determines whether the connection with the server is currently active. (Not necessarily logged in.
		 * For login status, use the <code>isLoggedIn()</code> method.)
		 *
		 * @return A boolean indicating whether the connection is active.
		 * @see	org.igniterealtime.xiff.core.XMPPConnection#isLoggedIn
		 */
		public function isActive():Boolean
		{
			return active;
		}
		
		/**
		 * Determines whether the user is connected and logged into the server.
		 *
		 * @return A boolean indicating whether the user is logged in.
		 * @see	org.igniterealtime.xiff.core.XMPPConnection#isActive
		 */
		public function isLoggedIn():Boolean
		{
			return loggedIn;
		}
		
		/**
		 * Issues a request for the information that must be submitted for registration with the server.
		 * When the data returns, a <code>RegistrationFieldsEvent.REG_FIELDS</code> event is dispatched
		 * containing the requested data.
		 */
		public function getRegistrationFields():void
		{
			var regIQ:IQ = new IQ( new EscapedJID(domain), IQ.GET_TYPE, XMPPStanza.generateID("reg_info_"), "getRegistrationFields_result", this, null);
			regIQ.addExtension(new RegisterExtension(regIQ.getNode()));
	
			send( regIQ );
		}
		
		/**
		 * Registers a new account with the server, sending the registration data as specified in the fieldMap@paramter.
		 *
		 * @param	fieldMap An object map containing the data to use for registration. The map should be composed of
		 * attribute:value pairs for each registration data item.
		 * @param	key (Optional) If a key was passed in the "data" field of the "registrationFields" event,
		 * that key must also be passed here.
		 * required field needed for registration.
		 */
		public function sendRegistrationFields( fieldMap:Object, key:String ):void
		{
			var regIQ:IQ = new IQ( new EscapedJID(domain), IQ.SET_TYPE, XMPPStanza.generateID("reg_attempt_"), "sendRegistrationFields_result", this, null );
			var ext:RegisterExtension = new RegisterExtension(regIQ.getNode());
	
			for( var i:String in fieldMap ) {
				ext[i] = fieldMap[i];
			}
			if (key != null) {
				ext.key = key;
			}
	
			regIQ.addExtension(ext);
			send( regIQ );
		}
		
		/**
		 * Changes the user's account password on the server. If the password change is successful,
		 * the class will broadcast a <code>ChangePasswordSuccessEvent.PASSWORD_SUCCESS</code> event.
		 *
		 * @param	newPassword The new password
		 */
		public function changePassword( newPassword:String ):void
		{
			var passwdIQ:IQ = new IQ( new EscapedJID(domain), IQ.SET_TYPE, XMPPStanza.generateID("pswd_change_"), "changePassword_result", this, null );
			var ext:RegisterExtension = new RegisterExtension(passwdIQ.getNode());
	
			ext.username = jid.escaped.bareJID;
			ext.password = newPassword;
	
			passwdIQ.addExtension(ext);
			send( passwdIQ );
		}
		
		/**
		 * Gets the fully qualified unescaped JID (user@server/resource) of the user. A fully-qualified JID includes
		 * the resource. A bare JID does not. To get the bare JID, use the <code>bareJID</code> property.
		 *
		 * @return The fully qualified unescaped JID
		 * @see	org.igniterealtime.xiff.core.UnescapedJID#bareJID
		 */
		public function get jid():UnescapedJID
		{
			return new UnescapedJID(myUsername + "@" + myDomain + "/" + myResource);
		}
		
		/**
		 * Choose the stream start and ending tags based on the given type.
		 * @param	type	One of: flash, terminatedFlash, standard, terminatedStandard.
		 */
		protected function chooseStreamTags(type:String):void
		{
			// Stream type lets user set opening/closing tag - some servers (jadc2s) prefer <stream:flash> to the standard
			// <stream:stream>
			
			openingStreamTag = '<?xml version="1.0"?>';
			if (type == "flash" || type == "terminatedFlash")
			{
				openingStreamTag += '<flash';
				closingStreamTag = '</flash:stream>';
			}
			else
			{
				openingStreamTag += '<stream';
				closingStreamTag = '</stream:stream>';
			}
			
			openingStreamTag += ':stream xmlns="' + XMPPStanza.CLIENT_NAMESPACE + '" ';
			
			if (type == "flash" || type == "terminatedFlash")
			{
				openingStreamTag += 'xmlns:flash="' + XMPPStanza.NAMESPACE_FLASH + '"';
			}
			else
			{
				openingStreamTag += 'xmlns:stream="' + XMPPStanza.NAMESPACE_STREAM + '"';
			}
			openingStreamTag += ' to="' + domain + '" version="' + XMPPStanza.CLIENT_VERSION + '"';
			
			if (type.indexOf("terminated") != -1)
			{
				openingStreamTag += ' /';
			}
			
			openingStreamTag += '>';
		}
		
		/**
		 * @private
		 */
		protected function changePassword_result( resultIQ:IQ ):void
		{
			if( resultIQ.type == IQ.RESULT_TYPE ) {
				var event:ChangePasswordSuccessEvent = new ChangePasswordSuccessEvent();
				dispatchEvent(event);
			}
			else {
				// We weren't expecting this
				dispatchError( "unexpected-request", "Unexpected Request", "wait", 400 );
			}
		}
		
		/**
		 * @private
		 */
		protected function getRegistrationFields_result( resultIQ:IQ ):void
		{
			try
			{
				var ext:RegisterExtension = resultIQ.getAllExtensionsByNS(RegisterExtension.NS)[0];
				var fields:Array = ext.getRequiredFieldNames(); //TODO, phase this out
				
				var event:RegistrationFieldsEvent = new RegistrationFieldsEvent();
				event.fields = fields;
				event.data = ext;
				
				dispatchEvent(event);
			}
			catch (e:Error)
			 {
			 	trace(e.getStackTrace());
			 }
		}
		
		/**
		 * @private
		 */
		protected function sendRegistrationFields_result( resultIQ:IQ ):void
		{
			if( resultIQ.type == IQ.RESULT_TYPE ) {

				var event:RegistrationSuccessEvent = new RegistrationSuccessEvent();
				dispatchEvent( event );
			}
			else {
				// We weren't expecting this
				dispatchError( "unexpected-request", "Unexpected Request", "wait", 400 );
			}
		}
		
		// Listener function from the ListenerXMLSocket
		/**
		 * @private
		 */
		protected function socketConnected(event:Event):void
		{
			active = true;
			sendXML( openingStreamTag );
			var connectionEvent:ConnectionSuccessEvent = new ConnectionSuccessEvent();
			dispatchEvent( connectionEvent );
		}
		
		/**
		 * @private
		 */
		protected function socketReceivedData( ev:DataEvent ):void
		{
			// parseXML is more strict in AS3 so we must check for the presence of flash:stream
			// the unterminated tag should be in the first string of xml data retured from the server
			if (!_expireTagSearch)
			{
				var pattern:RegExp = new RegExp("<flash:stream");
				var resultObj:Object = pattern.exec(ev.data);
				if (resultObj != null) // stop searching for unterminated node
				{
					ev.data = ev.data.concat("</flash:stream>");
					_expireTagSearch = true;
				}
			}
			
			if(ev.data == "</flash:stream>")
			{
				socketClosed(null);
				return;
			}
			
			var xmlData:XMLDocument = new XMLDocument();
			xmlData.ignoreWhite = this.ignoreWhite;
			xmlData.parseXML( ev.data );
			
			var event:IncomingDataEvent = new IncomingDataEvent();
			event.data = xmlData;
			dispatchEvent( event );
			
			// Read the data and send it to the appropriate parser
			var firstNode:XMLNode = xmlData.firstChild;
			var nodeName:String = firstNode.nodeName.toLowerCase();
			
			logger.info("INCOMING: {0}", firstNode);
			
			switch( nodeName )
			{
				case "stream:stream":
				case "flash:stream":
					_expireTagSearch = false;
					handleStream( firstNode );
					break;
					
				case "stream:error":
					handleStreamError( firstNode );
					break;
					
				case "iq":
					handleIQ( firstNode );
					break;
					
				case "message":
					handleMessage( firstNode );
					break;
					
				case "presence":
					handlePresence( firstNode );
					break;
					
				case "stream:features":
					handleStreamFeatures( firstNode );
					break;
					
				case "success":
					handleAuthentication( firstNode );
					break;

				case "failure":
					handleAuthentication( firstNode );
					break;
					
				default:
					// silently ignore lack of or unknown stanzas
					// if the app designer wishes to handle raw data they
					// can on "incomingData".
	
					// Use case: received null byte, XMLSocket parses empty document
					// sends empty document
					
					// I am enabling this for debugging
					dispatchError( "undefined-condition", "Unknown Error", "modify", 500 );
					break;
			}
		}
		
		/**
		 * @private
		 */
		protected function socketClosed(event:Event):void
		{
			var disconnectionEvent:DisconnectionEvent = new DisconnectionEvent();
			dispatchEvent( disconnectionEvent );
		}
		
		/**
		 * @private
		 */
		protected function handleStream( node:XMLNode ):void
		{
			sessionID = node.attributes.id;
			domain = node.attributes.from;
			
			for each(var childNode:XMLNode in node.childNodes)
			{
				if(childNode.nodeName == "stream:features")
				{
					handleStreamFeatures(childNode);
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function handleStreamFeatures( node:XMLNode ):void
		{
			if(!loggedIn)
			{
				for each(var feature:XMLNode in node.childNodes)
				{
					if (feature.nodeName == "starttls")
					{
						if (feature.firstChild && feature.firstChild.nodeName == "required")
						{
							// No TLS support yet
							dispatchError("TLS required", "The server requires TLS, but this feature is not implemented.", "cancel", 501);
							disconnect();
							return;
						}
					}
					else if (feature.nodeName == "mechanisms")
					{
						configureAuthMechanisms(feature);
					}
					else if (feature.nodeName == "compression")
					{
						// TODO: check for having "zlib" method.
						if (_compress)
						{
							configureStreamCompression();
						}
					}
					
		        }
		
				if (useAnonymousLogin || (username != null && username.length > 0))
				{
					beginAuthentication();
				}
				else
				{
					getRegistrationFields();
				}
			}
			else
			{
				bindConnection();
			}
		}
	
	    /**
		 * @private
		 */
	    protected function configureAuthMechanisms(mechanisms:XMLNode):void
	    {
	        var authMechanism:SASLAuth;
	        var authClass:Class;
	        for each(var mechanism:XMLNode in mechanisms.childNodes)
	        {
	        	authClass = saslMechanisms[mechanism.firstChild.nodeValue];
	   			if(useAnonymousLogin)
	   			{
	   				if(authClass == Anonymous)
	   					break;
	   			}
	   			else
	   			{
	   				if(authClass) break;
	   			}
	        }
	
	        if (!authClass) {
	        	dispatchError("SASL missing", "The server is not configured to support any available SASL mechanisms", "SASL", -1);
	        	return;
	        }
	
	        auth = new authClass(this);
	    }
		
		/**
		 *
		 */
		protected function configureStreamCompression():void
		{
			
		}
		
		/**
		 * @private
		 */
		protected function handleStreamError( node:XMLNode ):void
		{
			dispatchError( "service-unavailable", "Remote Server Error", "cancel", 502 );
			
			// Cancel everything by closing connection
			try {
				_socket.close();
			}
			catch (error:Error){
				
			}
			active = false;
			loggedIn = false;
			var event:DisconnectionEvent = new DisconnectionEvent();
			
			dispatchEvent( event );
		}
		
		protected function set active(flag:Boolean):void
		{
			if(flag)
			{
				_openConnections.push(this);
			}
			else
			{
				_openConnections.splice(_openConnections.indexOf(this), 1);
			}
			_active = flag;
		}
		
		protected function get active():Boolean
		{
			return _active;
		}
		
		public static function get openConnections():Array
		{
			return _openConnections;
		}
		
		/**
		 * @private
		 */
		protected function handleIQ( node:XMLNode ):IQ
		{
			var iq:IQ = new IQ();
			// Populate the IQ with the incoming data
			if( !iq.deserialize( node ) ) {
				throw new SerializationException();
			}
			
			// If it's an error, handle it
			
			if( iq.type == IQ.ERROR_TYPE) {
				dispatchError( iq.errorCondition, iq.errorMessage, iq.errorType, iq.errorCode );
			}
			else {
				
				// Start the callback for this IQ if one exists
				if( pendingIQs[iq.id] !== undefined ) {
					var callbackInfo:* = pendingIQs[iq.id];
					
					if(callbackInfo.methodScope && callbackInfo.methodName) {
						callbackInfo.methodScope[callbackInfo.methodName].apply( callbackInfo.methodScope, [iq] );
					}
					if (callbackInfo.func != null) {
						callbackInfo.func( iq );
					}
					pendingIQs[iq.id] = null;
					delete pendingIQs[iq.id];
				}
				else {
					var exts:Array = iq.getAllExtensions();
					for (var ns:String in exts) {
						// Static type casting
						var ext:IExtension = exts[ns] as IExtension;
						if (ext != null) {
							var event:IQEvent = new IQEvent(ext.getNS());
							event.data = ext;
							event.iq = iq;
							dispatchEvent( event );
						}
					}
				}
			}
	        return iq;
		}
		
		/**
		 * @private
		 */
		protected function handleMessage( node:XMLNode ):Message
		{
			var msg:Message = new Message();
			logger.debug("MESSAGE: {0}", msg);
			// Populate with data
			if( !msg.deserialize( node ) ) {
				throw new SerializationException();
			}
			// ADDED in error handling for messages
			if( msg.type == Message.ERROR_TYPE ) {
				var exts:Array = msg.getAllExtensions();
				dispatchError( msg.errorCondition, msg.errorMessage, msg.errorType, msg.errorCode, exts.length > 0 ? exts[0] : null);
			}
			else
			{
				var event:MessageEvent = new MessageEvent();
				event.data = msg;
				dispatchEvent( event );
			}
	        return msg;
		}
		
		/**
		 * @private
		 */
		private var presenceQueue:Array = [];
		private var presenceQueueTimer:Timer;
		protected function handlePresence( node:XMLNode ):Presence
		{
			if(!presenceQueueTimer)
			{
				presenceQueueTimer = new Timer(1, 1);
				presenceQueueTimer.addEventListener(TimerEvent.TIMER_COMPLETE, flushPresenceQueue);
			}
			
			var pres:Presence = new Presence();
			
			// Populate
			if( !pres.deserialize( node ) ) {
				throw new SerializationException();
			}
			
			presenceQueue.push(pres);
			
			presenceQueueTimer.reset();
			presenceQueueTimer.start();

	        return pres;
		}
		
		protected function flushPresenceQueue(event:TimerEvent):void
		{
			var presenceEvent:PresenceEvent = new PresenceEvent();
			presenceEvent.data = presenceQueue;
			dispatchEvent( presenceEvent );
			presenceQueue = [];
		}
		
		/**
		 * This fires the standard dispatchError method. need to add the appropriate error code
		 * @private
		 */
		protected function onIOError(event:IOErrorEvent):void
		{
			dispatchError( "service-unavailable", "Service Unavailable", "cancel", 503 );
		}
		
		/**
		 * @private
		 */
		protected function securityError(event:SecurityErrorEvent):void
		{
			trace("there was a security error of type: " + event.type + "\nError: " + event.text);
			dispatchError( "not-authorized", "Not Authorized", "auth", 401 );
		}
		
		/**
		 * @private
		 */
		protected function dispatchError( condition:String, message:String, type:String, code:Number, extension:Extension = null ):void
		{
			logger.error("Error: {0} - {1}", condition, message);
			var event:XIFFErrorEvent = new XIFFErrorEvent();
			event.errorCondition = condition;
			event.errorMessage = message;
			event.errorType = type;
			event.errorCode = code;
			event.errorExt = extension;
			dispatchEvent( event );
		}
		
		/**
		 * @private
		 */
		protected function sendXML( someData:* ):void
		{
			logger.info("OUTGOING: {0}", someData);
			// Data is untyped because it could be a string or XML
			_socket.send( someData );
			var event:OutgoingDataEvent = new OutgoingDataEvent();
			event.data = someData;
			dispatchEvent( event );
		}
		
		/**
		 * @private
		 */
		protected function beginAuthentication():void
		{
	        sendXML(auth.request);
		}
	
		/**
		 * @private
		 */
	    protected function handleAuthentication(responseBody:XMLNode):void
	    {
	        var status:Object = auth.handleResponse(0, responseBody);
	        if (status.authComplete)
	        {
	            if (status.authSuccess)
	            {
					loggedIn = true;
					restartStream();
	            }
	            else
	            {
					dispatchError("Authentication Error", "", "", 401);
	                disconnect();
	            }
	        }
	    }
	
		/**
		 * @private
		 */
	    protected function restartStream():void
	    {
	        sendXML(openingStreamTag);
	    }
	
		/**
		 * @private
		 */
	    protected function bindConnection():void
	    {
	    	var bindIQ:IQ = new IQ(null, "set");
	
			var bindExt:BindExtension = new BindExtension();
			if(resource)
	        	bindExt.resource = resource;
	
	        bindIQ.addExtension(bindExt);
	
			bindIQ.callback = handleBindResponse;
			bindIQ.callbackScope = this;
	
	        send(bindIQ);
	    }
	
		/**
		 * @private
		 */
	    protected function handleBindResponse(packet:IQ):void
	    {
	    	logger.debug("handleBindResponse: {0}", packet.getNode());
	    	var bind:BindExtension = packet.getExtension("bind") as BindExtension;
	
            var jid:UnescapedJID = bind.jid.unescaped;

            myResource = jid.resource;
            myUsername = jid.node;
            domain = jid.domain;

            establishSession();
	    }
	
		/**
		 * @private
		 */
	    private function establishSession():void
	    {
	        var sessionIQ:IQ = new IQ(null, "set");

	        sessionIQ.addExtension(new SessionExtension());
	
	        sessionIQ.callback = handleSessionResponse;
	        sessionIQ.callbackScope = this;
	
	        send(sessionIQ);
	    }
	
		/**
		 * @private
		 */
	    private function handleSessionResponse(packet:IQ):void
	    {
	    	logger.debug("handleSessionResponse: {0}", packet.getNode());
			dispatchEvent(new LoginEvent());
	    }
		
		/**
		 * @private
		 */
		protected function addIQCallbackToPending( id:String, callbackName:String, callbackScope:Object, callbackFunc:Function ):void
		{
			pendingIQs[id] = {methodName:callbackName, methodScope:callbackScope, func:callbackFunc};
		}
		
		/**
		 * The XMPP server to use for connection.
		 */
		public function get server():String
		{
			if (!myServer)
				return myDomain;
			return myServer;
		}
		
		/**
		 * @private
		 */
		public function set server( theServer:String ):void
		{
			myServer = theServer;
		}
		
		/**
		 * The XMPP domain to use with the server.
		 */
		public function get domain():String
		{
			if (!myDomain)
				return myServer;
			return myDomain;
		}
		
		/**
		 * @private
		 */
		public function set domain( theDomain:String ):void
		{
			myDomain = theDomain;
		}
		
		/**
		 * The username to use for connection. If this property is null when <code>connect()</code> is called,
		 * the class will fetch registration field data rather than attempt to login.
		 */
		public function get username():String
		{
			return myUsername;
		}
		
		/**
		 * @private
		 */
		public function set username( theUsername:String ):void
		{
			myUsername = theUsername;
		}
		
		/**
		 * The password to use when logging in.
		 */
		public function get password():String
		{
			return myPassword;
		}
		
		public function set password( thePassword:String ):void
		{
			myPassword = thePassword;
		}
		
		/**
		 * The resource to use when logging in. A resource is required (defaults to "XIFF") and
		 * allows a user to login using the same account simultaneously (most likely from multiple machines).
		 * Typical examples of the resource include "Home" or "Office" to indicate the user's current location.
		 */
		public function get resource():String
		{
			return myResource;
		}
		
		/**
		 * @private
		 */
		public function set resource( theResource:String ):void
		{
			if( theResource.length > 0 )
			{
				myResource = theResource;
			}
		}
		
		/**
		 * Whether to use anonymous login or not.
		 */
		public function get useAnonymousLogin():Boolean
		{
			return _useAnonymousLogin;
		}
		
		/**
		 * @private
		 */
		public function set useAnonymousLogin(value:Boolean):void
		{
			// set only if not connected
			if(!isActive()) _useAnonymousLogin = value;
		}
		
		/**
		 * The port to use when connecting. The default XMPP port is 5222.
		 */
		public function get port():Number
		{
			return myPort;
		}
		
		public function set port( portNum:Number ):void
		{
			myPort = portNum;
		}
	
		/**
		 * Determines whether whitespace will be ignored on incoming XML data.
		 * Behaves the same as <code>XML.ignoreWhite</code>
		 */
		public function get ignoreWhite():Boolean
		{
			return ignoreWhitespace;
		}
	
		public function set ignoreWhite( val:Boolean ):void
		{
			ignoreWhitespace = val;
		}
		
		/**
		 * Shall the zlib compression be allowed if the server supports it.
		 * @see http://xmpp.org/extensions/xep-0138.html
		 */
		public function get compress():Boolean
		{
			return _compress;
		}
		
		public function set compress(value:Boolean):void
		{
			_compress = value;
		}
		
		/**
		 *
		 * @return
		 */
		private function _createXmlSocket():XMLSocket {
			var socket:XMLSocket = new XMLSocket(server, port);
			socket.addEventListener(Event.CONNECT,socketConnected);
			socket.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			socket.addEventListener(Event.CLOSE,socketClosed);
			socket.addEventListener(DataEvent.DATA,socketReceivedData);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityError);
			return socket;
		}
	}
}
