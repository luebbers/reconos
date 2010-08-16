package de.upb.reconos.layout.editor;

import java.awt.Color;
import java.awt.Font;
import java.util.Vector;

import javax.swing.event.ChangeListener;

import de.upb.reconos.fpga.BlockRessource;
import de.upb.reconos.fpga.ColumnRessource;
import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.gui.Drawable;
import de.upb.reconos.gui.Interactable;
import de.upb.reconos.gui.RenderPanel;
import de.upb.reconos.gui.TextBlock;
import de.upb.reconos.gui.Vector2d;
import de.upb.reconos.layout.BusMacro;
import de.upb.reconos.layout.Layout;
import de.upb.reconos.layout.Slot;

public class DeviceRenderPanel extends RenderPanel implements ChangeListener {

	private static Color colorValidFill     = new Color(0,255,0);
	private static Color colorValidBorder   = new Color(0,128,0);
	private static Color colorInvalidFill   = new Color(255,0,0);
	private static Color colorInvalidBorder = new Color(128,0,0);
	private static Color colorBram        = Color.DARK_GRAY;
	private static Color colorBMBorder      = new Color(0,0,255);
	private static Color colorBMFill        = new Color(128,128,255);
	private static Color colorCLBs          = Color.GRAY;
	private static Color colorCPU         = Color.LIGHT_GRAY;
	
	private static final long serialVersionUID = 1L;

	private Editor editor;
	
	public DeviceRenderPanel(Editor e) {
		editor = e;
		center();
	}

	public void center(){
		super.center();
		translate(-0.5*getFPGAInfo().getWidth(),-0.5*getFPGAInfo().getHeight());
	}
	
	protected Vector<Interactable> getInteractables(){
		Vector<Interactable> ia = new Vector<Interactable>();
		if(getMyLayout() == null) return ia;
		for(Slot s : getMyLayout().getSlots()){
			Range r = s.getSliceRange();
			ia.add(new PRRInteractable(s,getMyLayout(),this));
			ia.add(new PRRBorderInteractable(r,PRRBorderInteractable.LEFT));
			ia.add(new PRRBorderInteractable(r,PRRBorderInteractable.RIGHT));
			ia.add(new PRRBorderInteractable(r,PRRBorderInteractable.BOTTOM));
			ia.add(new PRRBorderInteractable(r,PRRBorderInteractable.TOP));
			for(int i = 0; i < s.getBusMacros().size(); i++){
				ia.add(new BusMacroInteractable(s,i));
			}
		}
		
		ia.add(new DeviceInteractable(getFPGAInfo(),getMyLayout(),this));
		
		return ia;
	}	
	
	protected Vector<Drawable> getDrawables(){
		Vector<Drawable> drawables = new Vector<Drawable>();
		
		if(getFPGAInfo() == null) return null;
		
		if(getMyLayout() != null){
			for(Slot s : getMyLayout().getSlots()){
				Range r = s.getSliceRange();
				
				if(getFPGAInfo().isValidAGSliceRange(r) && getMyLayout().isValidSlot(s)) {
					drawables.add(new RangeDrawable(r,colorValidFill));
				}
				else {
					drawables.add(new RangeDrawable(r,colorInvalidFill));
				}
				
				for(int i = 0; i < s.getBusMacros().size(); i++){
					BusMacro bm = s.getBusMacros().get(i);
					Range a = bm.getRangeA();
					Range b = bm.getRangeB();
					
					if(getMyLayout().isValidBusMacro(bm) && s.isValidBusMacro(i)){
						drawables.add(new RangeDrawable(a,colorBMFill));
						drawables.add(new RangeDrawable(b,colorBMFill));
					}
					else{
						drawables.add(new RangeDrawable(a,colorInvalidFill));
						drawables.add(new RangeDrawable(b,colorInvalidFill));
					}
				}
			}
		}
		
		drawables.add(new GridDrawable(new Range(0,0,getFPGAInfo().getWidth(),
					getFPGAInfo().getHeight()),colorCLBs,0.1f));
		
		for(BlockRessource r : getFPGAInfo().getBlockRessources(null)){
			if(r.display) drawables.add(new RangeDrawable(r.range,r.color));
		}
		
		for(ColumnRessource v : getFPGAInfo().getColumnRessources(null)){
			if(v.display) drawables.add(new ColumnRessourceDrawable(v,0.5f));
		}
		
		if(getMyLayout() != null){
			for(Slot s : getMyLayout().getSlots()){
				Range r = s.getSliceRange();
	
				if(getFPGAInfo().isValidAGSliceRange(r) && getMyLayout().isValidSlot(s)) {
					drawables.add(new RangeBorderDrawable(r,colorValidBorder, 0.4f));
				}
				else {
					drawables.add(new RangeBorderDrawable(r,colorInvalidBorder, 0.4f));
				}
				
				for(int i = 0; i < s.getBusMacros().size(); i++){
					Vector2d bmCenterL = new Vector2d();
					TextBlock bmTextL = new TextBlock(bmCenterL);
					Vector2d bmCenterR = new Vector2d();
					TextBlock bmTextR = new TextBlock(bmCenterR);
					
					BusMacro bm = s.getBusMacros().get(i);
					Range a = bm.getRangeA();
					Range b = bm.getRangeB();
					
					if(getMyLayout().isValidBusMacro(bm) && s.isValidBusMacro(i)){
						drawables.add(new RangeBorderDrawable(a,colorBMBorder, 0.3f));
						drawables.add(new RangeBorderDrawable(b,colorBMBorder, 0.3f));
					}
					else{
						drawables.add(new RangeBorderDrawable(a,colorInvalidBorder, 0.3f));
						drawables.add(new RangeBorderDrawable(b,colorInvalidBorder, 0.3f));
					}
					
					bmCenterL.setX(0.5*(a.getXMin() + a.getXMax()));
					bmCenterL.setY(0.5*(a.getYMin() + a.getYMax()));
					if(bm.getLogicalDirection() == BusMacro.INPUT){
						bmTextL.setText("I");
					}
					else {
						bmTextL.setText("O");
					}
					
					drawables.add(bmTextL);
					
					bmCenterR.setX(0.5*(b.getXMin() + b.getXMax() + 1));
					bmCenterR.setY(0.5*(b.getYMin() + b.getYMax()));
					bmTextR.setText("" + i);
					drawables.add(bmTextR);
				}
				
				double x = 0.5*(r.getXMin() + r.getXMax());
				double y = 0.5*(r.getYMin() + r.getYMax());
				TextBlock text = new TextBlock(new Vector2d(x,y));
				
				text.font = new Font("monospaced",Font.BOLD,2);
				text.setText(s.getName());
				drawables.add(text);
			}
		}
		
		return drawables;
	}

	private Layout getMyLayout() {
		return editor.getMyLayout();
	}

	public DeviceInfo getFPGAInfo() {
		return editor.getFPGAInfo();
	}
}
