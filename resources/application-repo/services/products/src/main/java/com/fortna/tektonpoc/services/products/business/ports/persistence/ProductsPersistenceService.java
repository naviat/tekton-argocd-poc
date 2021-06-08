package com.fortna.tektonpoc.services.products.business.ports.persistence;

import com.fortna.tektonpoc.services.products.business.model.Product;

import java.util.List;

public interface ProductsPersistenceService {

    List<Product> fetchByLabels(List<String> labels);
}
