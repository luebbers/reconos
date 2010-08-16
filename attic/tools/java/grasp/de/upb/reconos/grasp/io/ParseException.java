package de.upb.reconos.grasp.io;

import java.io.IOException;

public class ParseException extends IOException {

	private static final long serialVersionUID = 1L;

	public ParseException(int line, String msg){
		super("parse error at line " + line + ": " + msg);
	}
}
