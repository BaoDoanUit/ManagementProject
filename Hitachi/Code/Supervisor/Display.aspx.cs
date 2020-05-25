using System;
using System.Linq;
using LogicTier.Controllers;
using System.Threading.Tasks;
using DevExpress.Web;
using System.Data;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data.SqlClient;
using LogicTier.Models;
using System.Collections.Generic;

namespace WebApplication.Pages.Suppervisor
{
    public partial class Display : Code.Permission
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                bindOultet();
                InfoCallback.JSProperties["cpAlert"] = "";
                cbProduct.JSProperties["cpProduct"] = "";
                bSave.Visible = blockEdit(cbOutlet.Value != null ? Convert.ToInt32(cbOutlet.Value) : -1);
            }

        }
        void bindOultet()
        {
            odsOutlet.SelectParameters["userName"].DefaultValue = userInfo.UserName;
            odsOutlet.DataBind();
            cbOutlet.DataBind();

            var getCheckIn = new AttendanceBL().getByReferences(userInfo.EmployeeId, null, DateTime.Now.ToString("yyyy-MM-dd"), null).FirstOrDefault();
            if (getCheckIn != null)
            {
                ListEditItem shopItem = cbOutlet.Items.FindByValue(getCheckIn.ShopId);
                if (shopItem != null)
                    cbOutlet.Items[shopItem.Index].Selected = true;
            }
        }
       
        protected void ASPxCallbackPanel1_Callback(object sender, CallbackEventArgsBase e)
        {
           
        }

        protected void rptDisplayImg_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Footer)
            {
                var ctl = e.Item.FindControl("bSave") as ASPxButton;
                if (ctl != null)
                    ctl.Visible = blockEdit(cbOutlet.Value != null ? Convert.ToInt32(cbOutlet.Value) : -1);
            }
        }

        protected void InfoCallback_Callback(object sender, CallbackEventArgsBase e)
        {
            string message = "";
            var param = e.Parameter.Split(';');

            switch (param[0].ToLower())
            {
                case "save":
                    {
                        if (cbOutlet.Value == null || cbProduct.Value == null)
                        {
                            message = "Bạn chưa chọn đủ thông tin.";
                            break;
                        }

                        int? shopId = Convert.ToInt32(cbOutlet.Value);
                        int? empId = userInfo.EmployeeId;
                        var getCheckIn = new AttendanceBL().getByReferences(empId, shopId, DateTime.Now.ToString("yyyy-MM-dd"), null).FirstOrDefault();
                        if (getCheckIn == null)
                        {
                            message = "Bạn chưa chấm công.";
                            break;
                        }


                        string product = cbProduct.Value.ToString();


                        DataTable dt = new DataTable();
                        dt.Columns.Add("EmployeeId", typeof(int));
                        dt.Columns.Add("ShopId", typeof(int));
                        dt.Columns.Add("ReportDate");
                        dt.Columns.Add("Product");
                        dt.Columns.Add("Model");
                        dt.Columns.Add("Display", typeof(int));
                        dt.Columns.Add("CreatedDate", typeof(DateTime));
                        dt.Columns.Add("BlockStatus", typeof(int));
                        dt.Columns.Add("Deleted", typeof(bool));

                        int block;
                        switch (userInfo.Position)
                        {
                            case "PC":
                                block = -1;
                                break;
                            case "Sup":
                                block = 0;
                                break;
                            case "PM":
                                block = 1;
                                break;
                            case "Admin":
                                block = 2;
                                break;
                            default:
                                block = -1;
                                break;
                        }

                        foreach (RepeaterItem item in rptProduct.Items)
                        {
                            object display = ((ASPxSpinEdit)item.FindControl("txDisplay")).Value;
                            var row = dt.NewRow();
                            row["EmployeeId"] = userInfo.EmployeeId;
                            row["ShopId"] = shopId;
                            row["ReportDate"] = DateTime.Now.ToString("yyyy-MM-dd");
                            row["Product"] = product;
                            row["Model"] = ((ASPxLabel)item.FindControl("lbModel")).Text;
                            row["Display"] = ToInt(display);
                            row["BlockStatus"] = block;
                            row["Deleted"] = 0;
                            dt.Rows.Add(row);
                        }

                        if (dt != null && dt.Rows.Count > 0)
                        {
                            string conn = ConfigurationManager.ConnectionStrings["techsourceConnection"].ConnectionString;

                            using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn, SqlBulkCopyOptions.FireTriggers))
                            {
                                bulkCopy.BatchSize = dt.Rows.Count;
                                bulkCopy.DestinationTableName = "StockDisplay";
                                foreach (DataColumn column in dt.Columns)
                                {
                                    bulkCopy.ColumnMappings.Add(column.ColumnName, column.ColumnName);
                                }
                                bulkCopy.WriteToServer(dt);
                                bulkCopy.Close();
                                dt.Dispose();
                            }
                            var lst = new StockDisplayBL().getProduct(userInfo.EmployeeId, ToInt(shopId), DateTime.Now.ToString("yyyy-MM-dd"), product);

                            rptProduct.DataSource = lst;
                            rptProduct.DataBind();
                            message = "Lưu thành công.";
                        }
                        else message = "Không lưu được.";
                        break;
                    }
                case "outlet":
                    {
                        string shopId = e.Parameter.Split(';')[1];
                        string product = null;

                        if (cbProduct.Value != null) product = cbProduct.Value.ToString();
                        if (!string.IsNullOrEmpty(product))
                        {

                            var lst = new StockDisplayBL().getProduct(userInfo.EmployeeId, ToInt(shopId), DateTime.Now.ToString("yyyy-MM-dd"), product);

                            rptProduct.DataSource = lst;
                            rptProduct.DataBind();

                            message = "outlet";
                        }
                        break;
                    }
                case "product":
                    {
                        string product = null, shop = null;
                        if (e.Parameter.Split(';')[1] != null && e.Parameter.Split(';')[1] != "null")
                            product = e.Parameter.Split(';')[1];

                        if (e.Parameter.Split(';')[2] != null && e.Parameter.Split(';')[2] != "null")
                            shop = e.Parameter.Split(';')[2];

                        var lst = new StockDisplayBL().getProduct(userInfo.EmployeeId, ToInt(shop), DateTime.Now.ToString("yyyy-MM-dd"), product);

                        rptProduct.DataSource = lst;
                        rptProduct.DataBind();

                        message = "product";
                        break;
                    }

            }
            InfoCallback.JSProperties["cpAlert"] = message;
        }
        protected void PhotoCallback_Callback(object sender, CallbackEventArgsBase e)
        {
            string message;
            var param = e.Parameter.Split(';');
            switch (param[0].ToLower())
            {
                case "imgproduct":
                    {
                        string product = null, shop = null;
                        if (e.Parameter.Split(';')[1] != null && e.Parameter.Split(';')[1] != "null")
                            product = e.Parameter.Split(';')[1];

                        if (e.Parameter.Split(';')[2] != null && e.Parameter.Split(';')[2] != "null")
                            shop = e.Parameter.Split(';')[2];

                        odsImgDisplay.SelectParameters["userName"].DefaultValue = userInfo.UserName;
                        odsImgDisplay.SelectParameters["empId"].DefaultValue = userInfo.EmployeeId.ToString();
                        odsImgDisplay.SelectParameters["shopId"].DefaultValue = shop;
                        odsImgDisplay.SelectParameters["product"].DefaultValue = product;
                        odsImgDisplay.SelectParameters["from"].DefaultValue = DateTime.Now.ToString("yyyy-MM-dd");
                        odsImgDisplay.SelectParameters["to"].DefaultValue = DateTime.Now.ToString("yyyy-MM-dd");
                        odsImgDisplay.DataBind();
                        rptDisplayImg.DataBind();

                        odModel.SelectParameters["empId"].DefaultValue = userInfo.EmployeeId.ToString();
                        odModel.SelectParameters["shopId"].DefaultValue = shop;
                        odModel.SelectParameters["rpDate"].DefaultValue = DateTime.Now.ToString("yyyy-MM-dd");
                        odModel.SelectParameters["product"].DefaultValue = product;
                        odModel.DataBind();
                        cbModel.DataBind();
                        cbModel.Value = null;
                        message = "imgProduct";
                        break;
                    }
                default:
                    {
                        string[] parameter = e.Parameter.Split(new string[] { "][" }, StringSplitOptions.None);
                        var file = !string.IsNullOrEmpty(parameter[0]) ? parameter[0] : null;
                        var shop = !string.IsNullOrEmpty(parameter[1]) ? parameter[1] : null;
                        var product = !string.IsNullOrEmpty(parameter[2]) ? parameter[2] : null;
                        var model = !string.IsNullOrEmpty(parameter[3]) ? parameter[3] : null;
                        var comment = !string.IsNullOrEmpty(parameter[4]) ? parameter[4] : null;

                        int? shopId = null;

                        if (file == null) { message = "Không chấm công được, bạn hãy chụp hình lại"; break; }
                        if (shop == null) { message = "Bạn chưa chọn Cửa hàng."; break; }
                        if (product == null) { message = "Bạn chưa chọn Product."; break; }
                        if (userInfo == null) { message = "Không Lưu được, bạne hãy đăng nhập lại."; break; }

                        shopId = Convert.ToInt32(shop);
                        var getCheckIn = new AttendanceBL().getByReferences(userInfo.EmployeeId, shopId, DateTime.Now.ToString("yyyy-MM-dd"), null).FirstOrDefault();
                        if (getCheckIn == null) { message = "Bạn chưa chấm công."; break; }

                        int? block;
                        switch (userInfo.Position)
                        {
                            case "PC":
                                block = -1;
                                break;
                            case "Sup":
                                block = 0;
                                break;
                            case "PM":
                                block = 1;
                                break;
                            case "Admin":
                                block = 2;
                                break;
                            default:
                                block = -1;
                                break;
                        }
                        ImageDisplay info = new ImageDisplay()
                        {
                            EmployeeId = userInfo.EmployeeId,
                            ShopId = shopId,
                            ReportDate = DateTime.Now,
                            Product = product,
                            Model = model,
                            BinaryImg = imageToByteArray(Base64ToImage(file)),
                            Comment = comment,
                            BlockStatus = block,
                            Deleted = false
                        };

                        var val = new ImageDisplayBL().Insert(info);
                        if (val)
                        {
                            odsImgDisplay.SelectParameters["userName"].DefaultValue = userInfo.UserName;
                            odsImgDisplay.SelectParameters["empId"].DefaultValue = userInfo.EmployeeId.ToString();
                            odsImgDisplay.SelectParameters["product"].DefaultValue = product;
                            odsImgDisplay.SelectParameters["from"].DefaultValue = DateTime.Now.ToString("yyyy-MM-dd");
                            odsImgDisplay.SelectParameters["to"].DefaultValue = DateTime.Now.ToString("yyyy-MM-dd");
                            odsImgDisplay.DataBind();
                            rptDisplayImg.DataBind();
                            message = "Lưu thành công.";
                        }
                        else
                        {
                            message = "Không lưu được, hãy chụp hình lại.";
                        }
                        break;
                    }
            }

            PhotoCallback.JSProperties["cpAlert"] = message;

        }

    }
}