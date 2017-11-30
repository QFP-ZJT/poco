package podo;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.channels.ScatteringByteChannel;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

public class hardupc {
	private static Map<String, String> alu;
	private static FileWriter w;

	public static void main(String[] args) throws IOException {
		alu = new HashMap<String, String>();
		w = new FileWriter(new File("hard_verilog"), false);
		alu.put("A", "0000");
		alu.put("B", "0001");
		alu.put("B++", "0010");
		alu.put("A+B", "0011");
		alu.put("A-B", "0100");
		alu.put("A^B", "0101");
		alu.put("A++", "0110");
		alu.put("A--", "0111");
		alu.put("A&B", "1000");
		alu.put("A|B", "1001");
		alu.put("~A", "1010");
		alu.put("A*B", "1011");
		alu.put("A/B", "1100");
		alu.put("B--", "1101");
		alu.put("N", "1111");

		Scanner scan_String = new Scanner(new File("hardexec"));
		Scanner scan;
		String temp;
		while (scan_String.hasNext()) {
			temp = scan_String.nextLine();
			System.out.println(temp);
			scan = new Scanner(temp);
			if (!scan.hasNext())
				continue;
			temp = scan.next();
			if (temp.equals("1") || temp.equals("0")) {
				w.write("                    endcase\n                end\n");
				w.write("    8'b" + scan.next() + ": begin\n                    case(slow)\n");
				temp = scan.next();
			}
			// temp == slow
			w.write("                        4'b" + temp + ": op <= 15'b" + alu.get(scan.next()) + scan.next() + scan.next() + scan.next()
					+ scan.next() + /* register */ scan.next() + scan.next() + scan.next() + scan.next() + scan.next()
					+ /* mar */scan.next() + scan.next()+";\n");
		}
		w.write("                    endcase\n                end\n");
		w.close();
	}

}
