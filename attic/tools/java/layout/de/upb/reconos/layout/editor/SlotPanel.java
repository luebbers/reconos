package de.upb.reconos.layout.editor;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;

import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.border.LineBorder;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.gui.RowLayout;
import de.upb.reconos.layout.Slot;

public class SlotPanel extends JPanel implements ChangeListener {
	
	private static final long serialVersionUID = 1L;
	
	public Slot slot;
	public DeviceInfo fpga;
	private JTextField nameInput;
	private JTextArea textArea;
	
	private String getText(){
		float clb = 100*slot.getSliceRange().getArea()/(float)(fpga.getHeight()*fpga.getWidth()); 
		//float bram = 100*fpga.getColumnRessource("RAMB16",slot.getSliceRange()).size()/(float)fpga.getColumnRessources("RAMB16").size();
		
		int clb1 = (int)clb;
		int clb2 = (int)(100*(clb - (int)clb));
		String clbs = "" + clb1 + "." + clb2;
		
		//int bram1 = (int)bram;
		//int bram2 = (int)(100*(bram - (int)bram));
		//String brams = "" + bram1 + "." + bram2;
		
		String t = "";
		t += " Slices: " + slot.getSliceRange() + "\n";
		//t += " BRAMs : " + slot.getBRAMRange() + "\n";
		t += " #CLBs : " + (slot.getSliceRange().getArea()/4) + "  (" + clbs + "%)\n";
		for(String s : fpga.getColumnRessourceNames()){
			t += " #" + s + ": " + fpga.getColumnRessource(s, slot.getSliceRange()).size() + "\n";
		}
		
		//t += " #BRAMs: " + (fpga.getColumnRessource("RAMB16",slot.getSliceRange()).size()) + "  (" + brams + "%)\n\n";
		return t;
	}
	
	public SlotPanel(Slot s, DeviceInfo fpga){
		this.fpga = fpga;
		slot = s;
		
		nameInput = new JTextField(17);

		//setLayout(new FlowLayout());
		setLayout(new RowLayout());
		setBorder(new LineBorder(Color.BLACK,1,true));
		
		if(s == null){
			textArea = new JTextArea();
			
			Dimension d = new Dimension(190,120);
			this.setMaximumSize(d);
			this.setMinimumSize(d);
			this.setPreferredSize(d);
			this.setSize(d);
			
			add(new JLabel("right-click on the"));
			add(new JLabel("FPGA to add a slot"));
			return;
		}
		
		
		textArea = new JTextArea(getText());		
		textArea.setEditable(false);
		//textArea.setBorder(new LineBorder(Color.BLACK,1,true));
		
		Font f = new Font("monospaced",0,getFont().getSize());
		textArea.setFont(f);
		
		JLabel l1 = new JLabel("Name:");
		
		add(l1);
		add(nameInput);
		add(textArea);
		
		slot.getSliceRange().addChangeListener(this);
		update();
	}
	
	public void update(){
		textArea.setText(getText());
		nameInput.setText(slot.getName());
	}

	public void stateChanged(ChangeEvent e) {
		update();
	}
	
}
