/*
 * Copyright (C) 2003-2012 Igniterealtime Community Contributors
 *
 *     Daniel Henninger
 *     Derrick Grigg <dgrigg@rogers.com>
 *     Juga Paazmaya <olavic@gmail.com>
 *     Nick Velloff <nick.velloff@gmail.com>
 *     Sean Treadway <seant@oncotype.dk>
 *     Sean Voisen <sean@voisen.org>
 *     Mark Walters <mark@yourpalmark.com>
 *     Michael McCarthy <mikeycmccarthy@gmail.com>
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.igniterealtime.xiff.data
{
	

	/**
	 * What is this?
	 */
	public class AbstractExtension extends Extension implements INodeProxy
	{
		public function AbstractExtension( parent:XML = null )
		{
			super(parent);
		}
		
		override public function set xml( node:XML ):void
		{
			super.xml = node;
			for each(var extNode:XML in node.children())
			{
				var ns:Namespace = extNode.namespace();
                                var extClass:Class = ExtensionClassRegistry.lookup(ns.uri, extNode.localName());
				if (extClass == null)
				{
					continue;
				}
				var ext:IExtension = new extClass();
				if (ext == null)
				{
					continue;
				}
				if (ext is INodeProxy)
				{
					INodeProxy(ext).xml = extNode;
				}
				addExtension(ext);
			}
		}
		
	}
}
