package de.upb.reconos.grasp.logic;

public class Signal {
	public static int READ  = 0x01;
	public static int WRITE = 0x02;
	
	public Type type;
	public String name;
	public int access;
}
