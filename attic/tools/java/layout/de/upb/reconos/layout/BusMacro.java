package de.upb.reconos.layout;

import de.upb.reconos.layout.editor.Range;

public class BusMacro {
	
	public static final int L2R = 0;
	public static final int R2L = 1;
	
	public static final int INPUT = 2;
	public static final int OUTPUT = 3;
	
	public static final int NARROW = 4;
	public static final int WIDE = 5;
	
	private int logicalDirection;
	private int physicalDirection;
	private int width;
	private boolean sync;
	private boolean enable;
	private Slot slot;
	
	private int locX;
	private int locY;
	
	public BusMacro(int logicalDirection, int physicalDirection){
		this.logicalDirection = logicalDirection;
		this.physicalDirection = physicalDirection;
		setWidth(NARROW);
		setSync(false);
		setEnable(true);
	}
	
	public Range getRange(){
		int w = 3;
		if(width == WIDE) w = 7;
		return new Range(locX,locY,locX + w, locY + 1);
	}
	
	public Range getRangeA(){
		return new Range(locX,locY,locX + 1, locY + 1);
	}
	
	public Range getRangeB(){
		int w = 3;
		if(width == WIDE){
			w = 7;
		}
		
		return new Range(locX + w - 1,locY,locX + w, locY + 1);
	}
	
	public boolean isEnable() {
		return enable;
	}
	public void setEnable(boolean enable) {
		this.enable = enable;
	}
	public int getLogicalDirection() {
		return logicalDirection;
	}
	public void setLogicalDirection(int logicalDirection) {
		this.logicalDirection = logicalDirection;
	}
	public int getPhysicalDirection() {
		return physicalDirection;
	}
	public void setPhysicalDirection(int physicalDirection) {
		this.physicalDirection = physicalDirection;
	}
	public boolean isSync() {
		return sync;
	}
	public void setSync(boolean sync) {
		this.sync = sync;
	}
	public int getWidth() {
		return width;
	}
	public void setWidth(int width) {
		this.width = width;
	}
	public int getLocX() {
		return locX;
	}
	public void setLocX(int loc_x) {
		this.locX = loc_x;
	}
	public int getLocY() {
		return locY;
	}
	public void setLocY(int loc_y) {
		this.locY = loc_y;
	}
	
	public void setLoc(int x, int y){
		setLocX(x);
		setLocY(y);
	}

	public Slot getSlot() {
		return slot;
	}

	public void setSlot(Slot slot) {
		this.slot = slot;
	}
	
	public String toString(){
		String s = physicalDirection == L2R ? "l2r" : "r2l";
		s += sync ? "_sync" : "_async";
		s += enable ? "_enable" : "";
		s += width == NARROW ? "_narrow" : "_wide";
		return s;
	}
}
