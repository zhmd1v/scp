import { useState, useEffect } from "react";
import { useAuth } from "../auth/AuthContext";
import { useTranslation } from "react-i18next";
import api from "../api/api";
import "./products.css";

export default function ProductManagement() {
    const { t } = useTranslation();
    const { user, token } = useAuth();
    const supplierId = user?.supplier_staff?.supplier_id || null;

    const [products, setProducts] = useState([]);
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);

    const [modalOpen, setModalOpen] = useState(false);
    const [editingProduct, setEditingProduct] = useState(null);

    const [categoryModalOpen, setCategoryModalOpen] = useState(false);
    const [newCategoryName, setNewCategoryName] = useState("");
    const [newCategoryDesc, setNewCategoryDesc] = useState("");

    const emptyForm = {
        name: "",
        description: "",
        sku: "",
        unit: "kg",
        unit_price: "",
        stock_quantity: "",
        minimum_order_quantity: "",
        is_available: true,
        category: "",
        image: null,
        imagePreview: null,
    };

    const [form, setForm] = useState(emptyForm);

    // LOAD PRODUCTS
    const loadProducts = async () => {
        try {
            const res = await api.get(
                `/catalog/suppliers/${supplierId}/products/`,
                { headers: { Authorization: `Token ${token}` } }
            );

            const mapped = res.data.map(p => ({
                id: p.id,
                name: p.name,
                description: p.description,
                sku: p.sku,
                unit: p.unit,
                unit_price: Number(p.unit_price),
                stock_quantity: Number(p.stock_quantity),
                minimum_order_quantity: Number(p.minimum_order_quantity),
                is_available: p.is_available,
                category: p.category ? p.category.id : "",
                category_obj: p.category,
                image: p.image,
                imagePreview: p.image,
            }));

            setProducts(mapped);
        } catch (err) {
            console.error(t("products.error_load"), err);
        }
        setLoading(false);
    };

    // LOAD CATEGORIES
    const loadCategories = async () => {
        try {
            const res = await api.get(`/catalog/categories/`, {
                headers: { Authorization: `Token ${token}` }
            });
            setCategories(res.data);
        } catch (err) {
            console.error("Error loading categories:", err);
        }
    };

    useEffect(() => {
        loadProducts();
        loadCategories();
    }, []);

    // MODAL HANDLERS
    const openAddModal = () => {
        setEditingProduct(null);
        setForm(emptyForm);
        setModalOpen(true);
    };

    const openEditModal = (product) => {
        setEditingProduct(product);
        setForm({
            ...product,
            category: product.category,
            image: null,
            imagePreview: product.image,
        });
        setModalOpen(true);
    };

    // IMAGE HANDLING
    const handleImage = (e) => {
        const file = e.target.files[0];
        if (!file) return;

        setForm(prev => ({
            ...prev,
            image: file,
            imagePreview: URL.createObjectURL(file),
        }));
    };

    // SAVE PRODUCT
    const saveProduct = async () => {
        if (!supplierId) {
            alert(t("products.error_no_supplier"));
            return;
        }

        const fd = new FormData();
        fd.append("supplier", supplierId);
        fd.append("name", form.name);
        fd.append("description", form.description);
        fd.append("sku", form.sku);
        fd.append("unit", form.unit);
        fd.append("unit_price", form.unit_price);
        fd.append("stock_quantity", form.stock_quantity);
        fd.append("minimum_order_quantity", form.minimum_order_quantity);
        fd.append("is_available", form.is_available);

        if (form.category) fd.append("category_id", form.category);
        if (form.image) fd.append("image", form.image);

        try {
            let res;
            if (editingProduct) {
                res = await api.patch(
                    `/catalog/products/${editingProduct.id}/update/`,
                    fd,
                    { headers: { Authorization: `Token ${token}` } }
                );
            } else {
                res = await api.post(
                    `/catalog/products/create/`,
                    fd,
                    { headers: { Authorization: `Token ${token}` } }
                );
            }

            setModalOpen(false);
            loadProducts();
        } catch (err) {
            console.error("Error saving product:", err.response?.data || err);
            alert(t("products.error_save"));
        }
    };

    // DELETE PRODUCT
    const deleteProduct = async (id) => {
        if (!window.confirm(t("products.confirm_delete"))) return;

        try {
            await api.delete(`/catalog/products/${id}/delete/`, {
                headers: { Authorization: `Token ${token}` }
            });
            loadProducts();
        } catch (err) {
            console.error(t("products.error_delete"), err);
        }
    };

    // TOGGLE AVAILABILITY
    const toggleAvailability = async (p) => {
        try {
            await api.patch(
                `/catalog/products/${p.id}/update/`,
                { is_available: !p.is_available },
                { headers: { Authorization: `Token ${token}` } }
            );
            loadProducts();
        } catch (err) {
            console.error(t("products.error_toggle"), err);
        }
    };

    // CREATE CATEGORY
    const createCategory = async () => {
        if (!newCategoryName.trim()) {
            alert("Category name is required");
            return;
        }

        try {
            await api.post(
                `/catalog/categories/create/`,
                {
                    name: newCategoryName,
                    description: newCategoryDesc,
                },
                { headers: { Authorization: `Token ${token}` } }
            );

            setCategoryModalOpen(false);
            setNewCategoryName("");
            setNewCategoryDesc("");

            loadCategories();
        } catch (err) {
            console.error("Error creating category:", err.response?.data || err);
            alert("Cannot create category");
        }
    };

    if (loading) return <div>{t("common.loading")}</div>;

    return (
        <div className="products-container">
            <h2>{t("products.title")}</h2>

            <div className="actions-row">
                <button className="btn-main" onClick={openAddModal}>
                    {t("products.add")}
                </button>

                {/* ADD CATEGORY BUTTON */}
                <button className="btn-main" onClick={() => setCategoryModalOpen(true)}>
                    {t("products.add_category") || "Add Category"}
                </button>
            </div>

            <table className="products-table">
                <thead>
                <tr>
                    <th>{t("products.image")}</th>
                    <th>{t("products.name")}</th>
                    <th>{t("products.unit")}</th>
                    <th>{t("products.price")}</th>
                    <th>{t("products.stock")}</th>
                    <th>{t("products.category")}</th>
                    <th>{t("products.available")}</th>
                    <th>{t("common.actions")}</th>
                </tr>
                </thead>

                <tbody>
                {products.map((p) => (
                    <tr key={p.id}>
                        <td>
                            {p.imagePreview ? (
                                <img src={p.imagePreview} className="thumb" alt="" />
                            ) : (
                                <div className="thumb placeholder">{t("products.no_image")}</div>
                            )}
                        </td>

                        <td>{p.name}</td>
                        <td>{p.unit}</td>
                        <td>{p.unit_price}</td>
                        <td>{p.stock_quantity}</td>
                        <td>{p.category_obj?.name}</td>

                        <td>
                            <button
                                className={p.is_available ? "tag green" : "tag red"}
                                onClick={() => toggleAvailability(p)}
                            >
                                {p.is_available ? t("common.yes") : t("common.no")}
                            </button>
                        </td>

                        <td>
                            <button className="btn-edit" onClick={() => openEditModal(p)}>
                                {t("common.edit")}
                            </button>
                            <button className="btn-delete" onClick={() => deleteProduct(p.id)}>
                                {t("common.delete")}
                            </button>
                        </td>
                    </tr>
                ))}
                </tbody>
            </table>

            {/* PRODUCT MODAL */}
            {modalOpen && (
                <div className="modal-overlay">
                    <div className="modal">
                        <h3>{editingProduct ? t("products.edit") : t("products.add")}</h3>

                        <div className="modal-body">
                            <label>{t("products.name")}</label>
                            <input
                                type="text"
                                value={form.name}
                                onChange={(e) => setForm({ ...form, name: e.target.value })}
                            />

                            <label>{t("products.description")}</label>
                            <input
                                type="text"
                                value={form.description}
                                onChange={(e) => setForm({ ...form, description: e.target.value })}
                            />

                            <label>{t("products.sku")}</label>
                            <input
                                type="text"
                                value={form.sku}
                                onChange={(e) => setForm({ ...form, sku: e.target.value })}
                            />

                            <label>{t("products.unit")}</label>
                            <input
                                type="text"
                                value={form.unit}
                                onChange={(e) => setForm({ ...form, unit: e.target.value })}
                            />

                            <label>{t("products.price")}</label>
                            <input
                                type="number"
                                value={form.unit_price}
                                onChange={(e) => setForm({ ...form, unit_price: e.target.value })}
                            />

                            <label>{t("products.stock")}</label>
                            <input
                                type="number"
                                value={form.stock_quantity}
                                onChange={(e) =>
                                    setForm({ ...form, stock_quantity: e.target.value })
                                }
                            />

                            <label>{t("products.min_order")}</label>
                            <input
                                type="number"
                                value={form.minimum_order_quantity}
                                onChange={(e) =>
                                    setForm({
                                        ...form,
                                        minimum_order_quantity: e.target.value,
                                    })
                                }
                            />

                            <label>{t("products.category")}</label>
                            <select
                                value={form.category}
                                onChange={(e) =>
                                    setForm({
                                        ...form,
                                        category: Number(e.target.value),
                                    })
                                }
                            >
                                <option value="">{t("products.select_category")}</option>
                                {categories.map((c) => (
                                    <option key={c.id} value={c.id}>
                                        {c.name}
                                    </option>
                                ))}
                            </select>

                            <label>{t("products.image")}</label>
                            <input type="file" onChange={handleImage} />

                            {form.imagePreview && (
                                <img src={form.imagePreview} className="preview" alt="" />
                            )}
                        </div>

                        <div className="modal-footer">
                            <button className="btn-cancel" onClick={() => setModalOpen(false)}>
                                {t("common.cancel")}
                            </button>
                            <button className="btn-save" onClick={saveProduct}>
                                {t("common.save")}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* CATEGORY MODAL */}
            {categoryModalOpen && (
                <div className="modal-overlay">
                    <div className="modal">
                        <h3>{t("products.add_category")}</h3>

                        <div className="modal-body">
                            <label>{t("products.category_name") || "Name"}</label>
                            <input
                                type="text"
                                value={newCategoryName}
                                onChange={(e) => setNewCategoryName(e.target.value)}
                            />

                            <label>{t("products.category_description") || "Description"}</label>
                            <input
                                type="text"
                                value={newCategoryDesc}
                                onChange={(e) => setNewCategoryDesc(e.target.value)}
                            />
                        </div>

                        <div className="modal-footer">
                            <button className="btn-cancel" onClick={() => setCategoryModalOpen(false)}>
                                {t("common.cancel")}
                            </button>
                            <button className="btn-save" onClick={createCategory}>
                                {t("common.save")}
                            </button>
                        </div>
                    </div>
                </div>
            )}

        </div>
    );
}


