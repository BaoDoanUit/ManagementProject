<%@ Page Title="Display" Language="C#"
    MasterPageFile="~/Layout.master" AutoEventWireup="true"
    CodeBehind="Display.aspx.cs"
    Inherits="WebApplication.Pages.Suppervisor.Display" %>

<%@ Import Namespace="System.Globalization" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="server">
    <style>
        .image-upload > div > input {
            display: none;
        }

        fieldset.scheduler-border {
            background-color: rgba(227, 229, 229, 0.09);
            border: 1px groove #ddd !important;
            padding: 0 1.4em 1.4em 1.4em !important;
            margin: 0 0 1.5em 0 !important;
            -webkit-box-shadow: 0px 0px 0px 0px #000;
            box-shadow: 0px 0px 0px 0px #000;
        }

        legend.scheduler-border {
            font-size: 1.2em !important;
            font-weight: bold !important;
            text-align: left !important;
            width: auto;
            padding: 35px 10px 0 10px;
            border-bottom: none;
        }
    </style>
    <script type="text/javascript">
        //for upload image
        $(document).ready(function () {
            //geoFindMe();
            var c = document.getElementById('fileUL');
            console.log('ready')
            if (c != null)
                c.addEventListener('change', handle);
        });
        function formatDate(dateObj) {
            var monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
            var curr_date = dateObj.getDate();
            var curr_month = dateObj.getMonth();
            curr_month = curr_month + 1;
            var curr_year = dateObj.getFullYear();
            var curr_min = dateObj.getMinutes();
            var curr_hr = dateObj.getHours();
            var curr_sc = dateObj.getSeconds();
            if (curr_month.toString().length == 1)
                curr_month = '0' + curr_month;
            if (curr_date.toString().length == 1)
                curr_date = '0' + curr_date;
            if (curr_hr.toString().length == 1)
                curr_hr = '0' + curr_hr;
            if (curr_min.toString().length == 1)
                curr_min = '0' + curr_min;

            return curr_year + "-" + curr_month + "-" + curr_date + " " + curr_hr + ":" + curr_min + ":" + curr_sc;
        }
        function handle(e) {
            console.log('handle');
            var MAX_HEIGHT = 768;
            var src = URL.createObjectURL(e.target.files[0]);

            var svrDate = '<%= DateTime.Now.ToString("ddd MMM dd yyyy HH:mm:ss", CultureInfo.InvariantCulture) %>';
            var d = new Date(Date.parse(svrDate));
            var dateStr = formatDate(d);

            var shop = Outlets.GetText();
            if (shop === null) {
                alert("Bạn chưa chọn Cửa hàng.");
                return;
            }
            var canvas = document.getElementById('canImg');
            var ctx = canvas.getContext('2d');

            var img = new Image();
            img.onload = function () {

                if (img.height > MAX_HEIGHT) {
                    img.width *= MAX_HEIGHT / img.height;
                    img.height = MAX_HEIGHT;
                }

                ctx.clearRect(0, 0, canvas.width, canvas.height);
                canvas.width = img.width;
                canvas.height = img.height;
                ctx.drawImage(img, 0, 0, img.width, img.height);

                ctx.font = "12px Arial";
                var gradient = ctx.createLinearGradient(0, 0, canvas.width, 0);
                gradient.addColorStop("0", "white");
                //gradient.addColorStop("0.1", "green");
                //gradient.addColorStop("0.2", "magenta");
                ctx.strokeStyle = gradient;
                ctx.strokeText(dateStr + " " + shop, 10, 25);
                //EXIF.getData(img, function () {
                //    alert(this.exifdata.Orientation);
                //    alert(EXIF.pretty(this));
                //});
            };

            img.src = src;
            $('#inputIMG').hide();
            $('#canvasIMG').show();
            btnClear.SetVisible(true);
            btnSave.SetVisible(true);
        }
        function clear(s, e) {
            $('#inputIMG').show();
            $('#canvasIMG').hide();
            btnSave.SetVisible(false);
            btnClear.SetVisible(false);
            console.log('clear');
        }
        function outletChange(s, e) {
            InfoCallback.PerformCallback('outlet;' + s.GetValue());
        }
        function productChange(s, e) {
            InfoCallback.PerformCallback('product;' + s.GetValue() + ';' + Outlets.GetValue());
        }
        function imgProductChange(s, e) {
            console.log('imgProductchange');
            PhotoCallback.PerformCallback('imgProduct;' + s.GetValue() + ';' + Outlets.GetValue());
        }

        function PhotoEndCallback(s, e) {
            if (s.cpAlert === 'imgProduct') {
                var c = document.getElementById('fileUL');
                console.log(c)
                if (c !== null)
                    c.addEventListener('change', handle);
            } else alert(s.cpAlert);
        }

        function SaveData() {
            var file = document.getElementById("canImg").toDataURL("image/jpeg");
            var images = file.replace("data:image/jpeg;base64,", "");
            //var lat = document.getElementById('lat').innerHTML;
            //var lng = document.getElementById('lng').innerHTML;

            var shop = Outlets.GetValue();
            if (shop === null)
                shop = '';

            var pd = cbimgProduct.GetValue();
            if (pd == null)
                pd = ''

            var model = cbModel.GetValue();
            if (model === null)
                model = '';

            var cm = txComment.GetText();
            if (cm === null)
                cm = '';

            var val = images + '][' + shop + '][' + pd + '][' + model + '][' + cm;
            return val;
        }
    </script>
    <dx:ASPxCallbackPanel ID="InfoCallback" runat="server" Width="100%"
        ClientInstanceName="InfoCallback" OnCallback="InfoCallback_Callback">
        <PanelCollection>
            <dx:PanelContent runat="server">
                <div class="row text-center">
                    <h3>Báo cáo Trưng bày</h3>
                    <h4></h4>
                    <div class="col-xs-12" style="margin-top: 5px;">
                        <div class="row" style="margin: 0 4px;">
                            <asp:HiddenField runat="server" ID="hfSaleId" />
                            <dx:ASPxComboBox runat="server" ID="cbOutlet" Width="100%"
                                NullText="Chọn cửa hàng"
                                DataSourceID="odsOutlet" ValueField="ShopId" ValueType="System.Int32"
                                ClientInstanceName="Outlets">
                                <ClientSideEvents SelectedIndexChanged="outletChange" />
                                <Columns>
                                    <dx:ListBoxColumn FieldName="ShopName" />
                                    <dx:ListBoxColumn FieldName="EmployeeName" />
                                </Columns>
                            </dx:ASPxComboBox>
                            <asp:ObjectDataSource ID="odsOutlet" runat="server" SelectMethod="getByParent" TypeName="LogicTier.Controllers.OutletBL">
                                <SelectParameters>
                                    <asp:Parameter Name="userName" Type="String" />
                                </SelectParameters>
                            </asp:ObjectDataSource>
                        </div>
                        <div class="row" style="margin: 4px 4px 0 4px;">
                            <dx:ASPxComboBox runat="server" ID="cbProduct"
                                ValueField="Product" Width="100%"
                                ValueType="System.String" NullText="Chọn Product"
                                ClientInstanceName="cbProduct" DataSourceID="odsProduct">
                                <ClientSideEvents SelectedIndexChanged="productChange" />
                                <Columns>
                                    <dx:ListBoxColumn FieldName="Product" />
                                </Columns>
                            </dx:ASPxComboBox>
                            <asp:ObjectDataSource ID="odsProduct" runat="server" SelectMethod="getDivision" TypeName="LogicTier.Controllers.ProductsBL">
                                <SelectParameters>
                                    <asp:Parameter DefaultValue="Product" Name="fieldName" Type="String" />
                                    <asp:Parameter Name="fieldValue" Type="String" />
                                    <asp:Parameter DefaultValue="Product" Name="fieldDisplay" Type="String" />
                                </SelectParameters>
                            </asp:ObjectDataSource>
                        </div>
                        <div class="row">
                            <fieldset class="scheduler-border">
                                <legend class="scheduler-border">Số lượng Trưng bày</legend>
                                <div class="row">
                                    <div class="col-xs-12">
                                        <asp:Repeater runat="server" ID="rptProduct">
                                            <HeaderTemplate>
                                                <div class="row text-primary">
                                                    <div class="col-xs-7 text-uppercase text-success">
                                                        Sản phẩm
                                                    </div>
                                                    <div class="col-xs-5 text-center text-uppercase text-success">
                                                        Trưng bày
                                                    </div>
                                                </div>
                                            </HeaderTemplate>
                                            <ItemTemplate>
                                                <div class="row marginTop20">
                                                    <div class="col-xs-7 text-info text-left">
                                                        <%# Container.ItemIndex + 1 %>.
                                                        <dx:ASPxLabel runat="server" ClientInstanceName="lbModel" ID="lbModel" Text='<%# Eval("Model") %>'></dx:ASPxLabel>
                                                    </div>
                                                    <div class="col-xs-5 text-center">
                                                        <dx:ASPxSpinEdit runat="server" ID="txDisplay"
                                                            ClientInstanceName="txDisplay" Width="100%"
                                                            MaxLength="2"
                                                            Text='<%# Convert.ToInt32(Eval("Display")) > 0 ? Eval("Display") : ""  %>'>
                                                            <SpinButtons ShowIncrementButtons="false"></SpinButtons>
                                                        </dx:ASPxSpinEdit>
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                        <%--   <asp:ObjectDataSource ID="odsStockDisplay" runat="server" SelectMethod="getProduct"
                                            TypeName="LogicTier.Controllers.StockDisplayBL">
                                            <SelectParameters>
                                                <asp:Parameter Name="empId" Type="Int32" />
                                                <asp:Parameter Name="shopId" Type="Int32" />
                                                <asp:Parameter Name="rpDate" Type="String" />
                                                <asp:Parameter Name="product" Type="String" />
                                            </SelectParameters>
                                        </asp:ObjectDataSource>--%>
                                    </div>
                                </div>
                            </fieldset>
                        </div>
                        <div class="row text-left">
                            <div class="col-xs-12">
                                <dx:ASPxButton runat="server" ID="bSave" ClientInstanceName="bSave"
                                    CssClass="btn btn-primary" Text="Lưu" AutoPostBack="false">
                                    <ClientSideEvents Click="function(s,e){InfoCallback.PerformCallback('Save');}" />
                                </dx:ASPxButton>
                            </div>
                        </div>

                    </div>
                </div>
            </dx:PanelContent>
        </PanelCollection>
    </dx:ASPxCallbackPanel>
    <dx:ASPxCallbackPanel ID="PhotoCallback" Width="100%" ClientInstanceName="PhotoCallback" OnCallback="PhotoCallback_Callback"
        runat="server">
        <ClientSideEvents EndCallback="PhotoEndCallback" />
        <PanelCollection>
            <dx:PanelContent>
                <div class="row marginTop20">
                    <fieldset class="scheduler-border">
                        <legend class="scheduler-border">Hình ảnh Trưng bày</legend>
                        <div class="row marginTop05">
                            <div class="col-xs-6">
                                <dx:ASPxComboBox runat="server" ID="cbimgProduct"
                                    ValueField="Product" Width="100%"
                                    ValueType="System.String" NullText="Chọn Product"
                                    ClientInstanceName="cbimgProduct" DataSourceID="odImgProduct">
                                    <ClientSideEvents SelectedIndexChanged="imgProductChange" />
                                    <Columns>
                                        <dx:ListBoxColumn FieldName="Product" />
                                    </Columns>
                                </dx:ASPxComboBox>
                                <asp:ObjectDataSource ID="odImgProduct" runat="server" SelectMethod="getDivision"
                                    TypeName="LogicTier.Controllers.ProductsBL">
                                    <SelectParameters>
                                        <asp:Parameter DefaultValue="Product" Name="fieldName" Type="String" />
                                        <asp:Parameter Name="fieldValue" Type="String" />
                                        <asp:Parameter DefaultValue="Product" Name="fieldDisplay" Type="String" />
                                    </SelectParameters>
                                </asp:ObjectDataSource>
                            </div>
                            <div class="col-xs-6">
                                <dx:ASPxComboBox runat="server" ID="cbModel" ValueType="System.String"
                                    NullText="Chọn Model" Width="100%"
                                    DataSourceID="odModel" ValueField="Model"
                                    ClientInstanceName="cbModel"
                                    IncrementalFilteringMode="Contains" TextFormatString="{0}"
                                    DropDownStyle="DropDownList">
                                    <Columns>
                                        <dx:ListBoxColumn FieldName="Model" />
                                    </Columns>
                                </dx:ASPxComboBox>
                                <asp:ObjectDataSource ID="odModel" runat="server" SelectMethod="getProduct" TypeName="LogicTier.Controllers.StockDisplayBL">
                                    <SelectParameters>
                                        <asp:Parameter Name="empId" Type="Int32" />
                                        <asp:Parameter Name="shopId" Type="Int32" />
                                        <asp:Parameter Name="rpDate" Type="String" />
                                        <asp:Parameter Name="product" Type="String" />
                                    </SelectParameters>
                                </asp:ObjectDataSource>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-xs-12">
                                <asp:Repeater runat="server" ID="rptDisplayImg" DataSourceID="odsImgDisplay"
                                    OnItemDataBound="rptDisplayImg_ItemDataBound">
                                    <HeaderTemplate>
                                        <div class="row" style="margin-top: 5px;">
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <div class="col-xs-6">
                                            <div class="thumbnail">
                                                <dx:ASPxBinaryImage runat="server" ID="iBinary" CssClass="img-responsive" Value='<%# Eval("BinaryImg") %>'></dx:ASPxBinaryImage>
                                                <div style="margin-top: 3px">
                                                    <dx:ASPxLabel runat="server" ID="lbComment" Text='<%# Eval("Comment") %>'></dx:ASPxLabel>
                                                </div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                    <AlternatingItemTemplate>
                                        <div class="col-xs-6">
                                            <div class="thumbnail">
                                                <dx:ASPxBinaryImage runat="server" ID="iBinary" CssClass="img-responsive" Value='<%# Eval("BinaryImg") %>'></dx:ASPxBinaryImage>
                                                <div style="margin-top: 3px">
                                                    <dx:ASPxLabel runat="server" ID="lbComment" Text='<%# Eval("Comment") %>'></dx:ASPxLabel>
                                                </div>
                                            </div>
                                        </div>
                                    </AlternatingItemTemplate>
                                    <FooterTemplate>
                                        <div class="col-xs-6">
                                            <div class="row">
                                                <div class="image-upload" id="dvPanel" runat="server">
                                                    <div id="inputIMG">
                                                        <label for="fileUL">
                                                            <img src="../../Content/Images/camera-icon.png" class="img-responsive" />
                                                        </label>
                                                        <input type="file" name="fileUL" id="fileUL" accept="image/*" capture="camera" />
                                                    </div>
                                                    <div id="canvasIMG" style="display: none;">
                                                        <canvas style="border: 1px solid dotted; margin: 0 auto;" id="canImg" class="img-responsive"></canvas>
                                                        <div style="margin-top: 3px">
                                                            <dx:ASPxTextBox runat="server" ID="txComment" ClientInstanceName="txComment" CssClass="text-justify" Width="100%" NullText="Nhập mô tả"></dx:ASPxTextBox>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="row">
                                                <div class="col-xs-6 text-left">
                                                    <dx:ASPxButton runat="server" ID="btnSave"
                                                        ClientInstanceName="btnSave" CssClass="btn btn-link"
                                                        Text="Lưu"
                                                        AutoPostBack="false"
                                                        ClientVisible="false">
                                                        <ClientSideEvents Click="function(s, e){
                                                                    var val = SaveData();
                                                                    PhotoCallback.PerformCallback(val);
                                                                }" />
                                                    </dx:ASPxButton>
                                                </div>
                                                <div class="col-xs-6 text-left">
                                                    <dx:ASPxButton runat="server" ID="btnClear"
                                                        ClientInstanceName="btnClear" CssClass="btn btn-link"
                                                        Text="Xóa"
                                                        AutoPostBack="false"
                                                        ClientVisible="false">
                                                        <ClientSideEvents Click="clear" />
                                                    </dx:ASPxButton>
                                                </div>
                                            </div>
                                        </div>
                                        </div>
                                    </FooterTemplate>
                                </asp:Repeater>
                                <asp:ObjectDataSource ID="odsImgDisplay" runat="server" SelectMethod="getList" TypeName="LogicTier.Controllers.ImageDisplayBL">
                                    <SelectParameters>
                                        <asp:Parameter Name="userName" Type="String" />
                                        <asp:Parameter Name="id" Type="Int64" />
                                        <asp:Parameter Name="empId" Type="Int32" />
                                        <asp:Parameter Name="shopId" Type="Int32" />
                                        <asp:Parameter Name="product" Type="String" />
                                        <asp:Parameter Name="from" Type="String" />
                                        <asp:Parameter Name="to" Type="String" />
                                    </SelectParameters>
                                </asp:ObjectDataSource>
                            </div>
                        </div>
                    </fieldset>
                </div>
            </dx:PanelContent>
        </PanelCollection>
    </dx:ASPxCallbackPanel>
</asp:Content>
