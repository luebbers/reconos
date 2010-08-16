package de.upb.reconos.layout.editor;

import java.awt.Cursor;
import java.awt.event.MouseEvent;

import javax.swing.event.ChangeListener;

import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.gui.Interactable;
import de.upb.reconos.gui.Vector2d;
import de.upb.reconos.layout.Layout;

public class DeviceInteractable implements Interactable {

	private DeviceInfo fpgaInfo;
	private Layout layout;
	private ChangeListener changeListener;
	
	public DeviceInteractable(DeviceInfo f, Layout l, ChangeListener cl){
		fpgaInfo = f;
		layout = l;
		changeListener = cl;
	}
	
	public boolean contains(double x, double y) {
		return x > 0 && x < fpgaInfo.getWidth() && y > 0 && y < fpgaInfo.getHeight();
	}

	public void dragReleased(double x, double y) {}
	public void dragTo(double x, double y) {}

	public Cursor getCursor() {
		return null;
	}

	public Vector2d getPosition() {
		return null;
	}

	public boolean isDraggable() {
		return false;
	}

	public void onClick(MouseEvent e, double x, double y) {
		if(e.getButton() == 3){
			DeviceMenu menu = new DeviceMenu(layout,changeListener);
			menu.show(e.getComponent(), e.getX(), e.getY());
		}
	}
}
