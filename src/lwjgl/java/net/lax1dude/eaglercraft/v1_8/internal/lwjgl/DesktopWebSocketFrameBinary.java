/*
 * Copyright (c) 2024 lax1dude. All Rights Reserved.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * 
 */

package net.lax1dude.eaglercraft.v1_8.internal.lwjgl;

import java.io.InputStream;

import net.lax1dude.eaglercraft.v1_8.EaglerInputStream;
import net.lax1dude.eaglercraft.v1_8.internal.IWebSocketFrame;
import net.lax1dude.eaglercraft.v1_8.internal.PlatformRuntime;

public class DesktopWebSocketFrameBinary implements IWebSocketFrame {

	private final byte[] byteArray;
	private final long timestamp;

	public DesktopWebSocketFrameBinary(byte[] byteArray) {
		this.byteArray = byteArray;
		this.timestamp = PlatformRuntime.steadyTimeMillis();
	}

	@Override
	public boolean isString() {
		return false;
	}

	@Override
	public String getString() {
		return null;
	}

	@Override
	public byte[] getByteArray() {
		return byteArray;
	}

	@Override
	public InputStream getInputStream() {
		return new EaglerInputStream(byteArray);
	}

	@Override
	public int getLength() {
		return byteArray.length;
	}

	@Override
	public long getTimestamp() {
		return timestamp;
	}

}