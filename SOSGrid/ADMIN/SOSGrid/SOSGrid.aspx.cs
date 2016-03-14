using System;
using Microsoft.SharePoint;
using Microsoft.SharePoint.WebControls;

using Microsoft.SharePoint.Administration;
using System.Data;
using System.Web.UI.WebControls;
using System.Drawing;

namespace SOSGrid.Layouts.SOSGrid
{
    public partial class SOSGrid : LayoutsPageBase
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            //schema
            DataTable t = new DataTable();
            t.Columns.Add("machine");
            t.Columns.Add("type");
            t.Columns.Add("status");

            //gather
            SPFarm f = SPFarm.Local;
            foreach (SPService s in f.Services)
            {
                foreach (SPServiceInstance i in s.Instances)
                {
                    try
                    {
                        DataRow r = t.Rows.Add();
                        r["machine"] = i.Server.Address.ToString() + "," + i.Server.Id.ToString(); ;
                        r["type"] = i.TypeName;
                        r["status"] = i.Status.ToString();
                        t.Rows.Add(r);
                    }
                    catch (System.ArgumentException) { }
                }
            }

            //sort
            DataView dv = new DataView(t);
            dv.Sort = "machine, type";
            t = dv.ToTable();

            //reshape (rows = all unique services, cols = all unique machines)
            DataTable final = new DataTable();
            final.Columns.Add("Service");

            DataTable uniqueMachines = dv.ToTable(true, "machine");
            foreach (DataRow row in uniqueMachines.Rows)
            {
                final.Columns.Add(row[0].ToString());
            }

            DataTable uniqueTypes = dv.ToTable(true, "type");
            foreach (DataRow row in uniqueTypes.Rows)
            {
                DataRow nr = final.NewRow();
                nr["Service"] = row[0];
                final.Rows.Add(nr);
            }

            foreach (DataRow row in t.Rows)
            {
                int x = findIndex(uniqueMachines, "machine", row["machine"].ToString());
                int y = findIndex(uniqueTypes, "type", row["type"].ToString());
                final.Rows[y][x + 1] = row["status"];
            }

            //display
            SOSGridView.DataSource = final;
            SOSGridView.AutoGenerateColumns = false;
            foreach (DataColumn dc in final.Columns)
            {
                BoundField bf = new BoundField();
                if (dc.ColumnName.Contains(","))
                {
                    string guid = dc.ColumnName.Split(',')[0];
                    string machine = dc.ColumnName.Split(',')[1];
                    bf.HeaderText = String.Format("<a href=\"/_admin/Server.aspx?ServerId={1}&View=All&RoleName=\">{0}</a>", guid, machine);
                    bf.HtmlEncode=false;
                    bf.DataField = dc.ColumnName;
                }
                else
                {
                    bf.HeaderText = dc.ColumnName;
                    bf.DataField = dc.ColumnName;
                }
                SOSGridView.Columns.Add(bf);
            }
            SOSGridView.DataBind();
        }

        public int findIndex(DataTable table, string sort, string key)
        {
            DataView dv = new DataView(table);
            dv.Sort = sort;
            return dv.Find(key);
        }

        public void RowDataBound(Object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                int i = 0;
                foreach (TableCell c in e.Row.Cells)
                {

                    if (i > 0)
                    {
                        // conditional formatting
                        if (String.IsNullOrEmpty(c.Text) || c.Text == "&nbsp;")
                        {
                            c.BackColor = Color.White;
                        }
                        else if (c.Text == "Online")
                        {
                            c.BackColor = Color.LightGreen;
                        }
                        else if (c.Text.StartsWith("St"))
                        {
                            c.BackColor = Color.Yellow;
                        }
                        else
                        {
                            c.BackColor = Color.LightGray;
                        }
                    }
                    i++;

                }
            }
        }
    }
}
