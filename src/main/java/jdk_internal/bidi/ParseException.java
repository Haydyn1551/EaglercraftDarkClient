/*
 * Copyright (c) 1996, 2019, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

/*
 * (C) Copyright Taligent, Inc. 1996, 1997 - All Rights Reserved
 * (C) Copyright IBM Corp. 1996 - 1998 - All Rights Reserved
 *
 *   The original version of this source code and documentation is copyrighted
 * and owned by Taligent, Inc., a wholly-owned subsidiary of IBM. These
 * materials are provided under terms of a License Agreement between Taligent
 * and Sun. This technology is protected by multiple US and International
 * patents. This notice and attribution to Taligent may not be removed.
 *   Taligent is a registered trademark of Taligent, Inc.
 *
 */

package jdk_internal.bidi;

/**
 * Signals that an error has been reached unexpectedly while parsing.
 * 
 * @see java.lang.Exception
 * @see java.text.Format
 * @see java.text.FieldPosition
 * @author Mark Davis
 * @since 1.1
 */
public class ParseException extends Exception {

	private static final long serialVersionUID = 2703218443322787634L;

	/**
	 * Constructs a ParseException with the specified detail message and offset. A
	 * detail message is a String that describes this particular exception.
	 *
	 * @param s           the detail message
	 * @param errorOffset the position where the error is found while parsing.
	 */
	public ParseException(String s, int errorOffset) {
		super(s);
		this.errorOffset = errorOffset;
	}

	/**
	 * Returns the position where the error was found.
	 *
	 * @return the position where the error was found
	 */
	public int getErrorOffset() {
		return errorOffset;
	}

	// ============ privates ============
	/**
	 * The zero-based character offset into the string being parsed at which the
	 * error was found during parsing.
	 * 
	 * @serial
	 */
	private int errorOffset;
}
