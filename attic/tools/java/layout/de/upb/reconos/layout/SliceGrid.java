package de.upb.reconos.layout;

import de.upb.reconos.fpga.BlockRessource;
import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.layout.editor.Range;

public class SliceGrid {
	private int[][] slices;
	private DeviceInfo fpga;
	
	public SliceGrid(DeviceInfo fpga){
		this.fpga = fpga;
		slices = new int[fpga.getWidth()][fpga.getHeight()];
	}
	
	public void clear(){
		for(int i = 0; i < fpga.getWidth(); i++){
			for(int j = 0; j < fpga.getHeight(); j++){
				slices[i][j] = 0;
			}
		}
		
		for(BlockRessource cpu : fpga.getBlockRessources(null)){
			setSliceRange(cpu.range,0xFFFFFFFF,0xFFFFFFFF);
		}
	}
	
	public void setSliceRange(Range r, int value, int mask){
		value = value & mask;
		for(int y = r.getYMin(); y <= r.getYMax(); y++){
			for(int x = r.getXMin(); x <= r.getXMax(); x++){
				slices[x][y] = (slices[x][y] & ~mask) | value;
			}
		}
	}
	
	
	public void addSlot(Slot s, int idx){
		setSliceRange(s.getSliceRange(), idx, 0x000000FF);
		for(int i = 0; i < s.getBusMacros().size(); i++){
			BusMacro bm = s.getBusMacros().get(i);
			setSliceRange(bm.getRangeA(),0x0000FF00, 0x0000FF00);
		}
	}
	
	public boolean addBusMacro(BusMacro bm){
		setSliceRange(bm.getRangeA(),0x0000FF00, 0x0000FF00);
		return true;
	}
	
}
